<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Escalation;
use App\Models\IncompleteRecord;
use App\Models\Milestone;
use App\Models\WeeklySummary;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AutomationController extends Controller
{
    public function getReminders(Request $request): JsonResponse
    {
        $reminders = Milestone::with([
            'application:id,student_id',
            'application.student:id,name,student_id',
        ])
            ->where('is_completed', false)
            ->whereHas(
                'application',
                fn ($query) => $query->visibleTo($request->user()),
            )
            ->whereDate('due_date', '<=', Carbon::today()->addDays(14))
            ->orderBy('due_date')
            ->orderByDesc('priority')
            ->limit(100)
            ->get()
            ->map(fn (Milestone $milestone): array => [
                'id' => $milestone->id,
                'student_name' => $milestone->application->student->name,
                'student_id' => $milestone->application->student->student_id,
                'reminder_type' => $milestone->type,
                'message' => $milestone->title.': '.$milestone->description,
                'due_date' => $milestone->due_date->format('Y-m-d'),
                'is_completed' => $milestone->is_completed,
                'priority' => $milestone->priority,
            ]);

        return response()->json($reminders);
    }

    public function getIncompleteRecords(Request $request): JsonResponse
    {
        $records = IncompleteRecord::with(['student:id,name,student_id'])
            ->where('resolved', false)
            ->whereHas('application', function ($query) use ($request): void {
                $query->visibleTo($request->user())
                    ->whereColumn('applications.student_id', 'incomplete_records.student_id');
            })
            ->orderByRaw("FIELD(severity, 'critical', 'high', 'medium', 'low')")
            ->orderByDesc('created_at')
            ->limit(100)
            ->get()
            ->map(fn (IncompleteRecord $record): array => [
                'id' => $record->id,
                'student_name' => $record->student->name,
                'student_id' => $record->student->student_id,
                'missing_field' => $record->missing_field,
                'record_type' => $record->record_type,
                'severity' => $record->severity,
                'days_incomplete' => $record->created_at->diffInDays(now()),
                'last_updated' => $record->updated_at->format('Y-m-d'),
            ]);

        return response()->json($records);
    }

    public function getEscalations(Request $request): JsonResponse
    {
        $escalations = Escalation::with([
            'student:id,name,student_id',
            'assignee:id,name',
            'application:id,student_id,updated_at',
        ])
            ->whereHas('application', function ($query) use ($request): void {
                $query->visibleTo($request->user())
                    ->whereColumn('applications.student_id', 'escalations.student_id');
            })
            ->whereIn('status', ['open', 'in_progress'])
            ->orderByRaw("FIELD(escalation_level, 'critical', 'high', 'medium', 'low')")
            ->orderByDesc('escalated_at')
            ->limit(100)
            ->get()
            ->map(fn (Escalation $escalation): array => [
                'id' => $escalation->id,
                'student_name' => $escalation->student->name,
                'student_id' => $escalation->student->student_id,
                'application_id' => $escalation->application_id,
                'escalation_reason' => $escalation->escalation_reason,
                'escalation_level' => $escalation->escalation_level,
                'status' => $escalation->status,
                'assigned_to' => $escalation->assignee?->name ?? 'Unassigned',
                'days_stalled' => $escalation->application->updated_at->diffInDays(now()),
                'escalated_at' => $escalation->escalated_at->format('Y-m-d'),
            ]);

        return response()->json($escalations);
    }

    public function getWeeklySummary(): JsonResponse
    {
        $summaries = WeeklySummary::orderByDesc('week_start')
            ->limit(4)
            ->get()
            ->map(fn (WeeklySummary $summary): array => [
                'id' => $summary->id,
                'week_label' => $summary->week_label,
                'week_start' => $summary->week_start->format('Y-m-d'),
                'week_end' => $summary->week_end->format('Y-m-d'),
                'total_applications' => $summary->total_applications,
                'applications_submitted' => $summary->applications_submitted,
                'applications_reviewed' => $summary->applications_reviewed,
                'interviews_scheduled' => $summary->interviews_scheduled,
                'offers_received' => $summary->offers_received,
                'placements_confirmed' => $summary->placements_confirmed,
                'rejected' => $summary->rejected,
                'pending_review' => $summary->pending_review,
                'placement_rate' => (int) $summary->total_applications === 0
                    ? 0
                    : round(($summary->placements_confirmed / $summary->total_applications) * 100, 2),
            ]);

        return response()->json($summaries);
    }
}
