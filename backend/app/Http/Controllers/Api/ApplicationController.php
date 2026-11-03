<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Application;
use App\Models\IncompleteRecord;
use App\Models\Milestone;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class ApplicationController extends Controller
{
    private const STAGES = [
        'application',
        'verification',
        'endorsement',
        'partner_submission',
        'interview',
        'placement_confirmation',
    ];

    public function index(): JsonResponse
    {
        $applications = Application::with('student:id,name,student_id')
            ->latest('updated_at')
            ->limit(100)
            ->get()
            ->map(fn (Application $application): array => [
                'id' => $application->id,
                'application_number' => $application->application_number,
                'student_name' => $application->student->name,
                'student_id' => $application->student->student_id,
                'company_name' => $application->company_name,
                'position' => $application->position,
                'stage' => $application->status,
                'workflow_state' => $application->workflow_state,
                'interview_status' => $application->interview_status,
                'updated_at' => $application->updated_at?->toIso8601String(),
            ]);

        return response()->json($applications);
    }

    public function updateWorkflow(Request $request, Application $application): JsonResponse
    {
        $validated = $request->validate([
            'stage' => ['required', 'string', Rule::in(self::STAGES)],
            'interview_status' => [
                'sometimes',
                'string',
                Rule::in(['not_scheduled', 'scheduled', 'completed', 'offer_received', 'declined']),
            ],
        ]);

        $currentIndex = array_search($application->status, self::STAGES, true);
        $targetIndex = array_search($validated['stage'], self::STAGES, true);
        $isInterviewUpdate = $application->status === 'interview'
            && $validated['stage'] === 'interview'
            && array_key_exists('interview_status', $validated);

        if ($currentIndex === false || $targetIndex === false
            || (!$isInterviewUpdate && $targetIndex !== $currentIndex + 1)) {
            $this->rejectWorkflowTransition(
                $application,
                $validated['stage'],
                'workflow_transition_invalid',
                'This application cannot move to the requested workflow stage. Contact the coordinator.',
            );
        }

        if ($isInterviewUpdate) {
            $application->interview_status = $validated['interview_status'];
            if ($validated['interview_status'] === 'scheduled') {
                $application->interview_scheduled_at = now();
            }
            if ($validated['interview_status'] === 'offer_received') {
                $application->offer_received_at = now();
            }
            if ($validated['interview_status'] === 'declined') {
                $application->workflow_state = 'rejected';
                $application->rejected_at = now();
            }
        } else {
            if ($application->status === 'verification') {
                $hasIncompleteRecords = $application->incompleteRecords()->where('resolved', false)->exists();
                $hasOpenRequirements = $application->milestones()
                    ->where('type', 'requirement')
                    ->where('is_completed', false)
                    ->exists();

                if ($hasIncompleteRecords || $hasOpenRequirements) {
                    $this->rejectWorkflowTransition(
                        $application,
                        $validated['stage'],
                        'workflow_requirements_incomplete',
                        'Resolve all missing records and required documents before endorsement.',
                    );
                }
            }

            if ($validated['stage'] === 'placement_confirmation'
                && $application->interview_status !== 'offer_received') {
                $this->rejectWorkflowTransition(
                    $application,
                    $validated['stage'],
                    'workflow_offer_required',
                    'A partner offer must be recorded before placement can be confirmed.',
                );
            }

            $application->status = $validated['stage'];
            $application->workflow_state = $validated['stage'] === 'placement_confirmation'
                ? 'approved'
                : 'in_progress';

            match ($validated['stage']) {
                'verification' => $application->submitted_at = now(),
                'endorsement' => $application->verified_at = now(),
                'partner_submission' => $application->endorsed_at = now(),
                'interview' => $application->partner_submitted_at = now(),
                'placement_confirmation' => $application->confirmed_at = now(),
                default => null,
            };
        }

        $application->save();
        $application->escalations()
            ->whereIn('status', ['open', 'in_progress'])
            ->update([
                'status' => 'resolved',
                'resolved_at' => now(),
                'action_taken' => 'Application record updated.',
                'updated_at' => now(),
            ]);

        return response()->json([
            'data' => [
                'id' => $application->id,
                'stage' => $application->status,
                'workflow_state' => $application->workflow_state,
                'interview_status' => $application->interview_status,
                'updated_at' => $application->updated_at?->toIso8601String(),
            ],
            'message' => 'Application workflow updated.',
        ]);
    }

    private function rejectWorkflowTransition(
        Application $application,
        string $requestedStage,
        string $errorCode,
        string $message,
    ): never {
        Log::warning('workflow.transition_rejected', [
            'application_id' => $application->id,
            'requested_stage' => $requestedStage,
            'error_code' => $errorCode,
            'human_action_required' => true,
        ]);

        throw ValidationException::withMessages(['stage' => [$message]]);
    }

    public function completeMilestone(Milestone $milestone): JsonResponse
    {
        if (!$milestone->is_completed) {
            $milestone->is_completed = true;
            $milestone->completed_at = now();
            $milestone->save();
        }

        return response()->json([
            'data' => [
                'id' => $milestone->id,
                'is_completed' => $milestone->is_completed,
                'completed_at' => $milestone->completed_at?->toIso8601String(),
            ],
            'message' => 'Requirement marked complete.',
        ]);
    }

    public function resolveIncompleteRecord(IncompleteRecord $record): JsonResponse
    {
        if (!$record->resolved) {
            $record->resolved = true;
            $record->resolved_at = now();
            $record->save();
        }

        return response()->json([
            'data' => [
                'id' => $record->id,
                'resolved' => $record->resolved,
                'resolved_at' => $record->resolved_at?->toIso8601String(),
            ],
            'message' => 'Incomplete record resolved.',
        ]);
    }
}
