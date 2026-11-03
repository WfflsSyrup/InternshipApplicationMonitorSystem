<?php

namespace App\Console\Commands;

use App\Models\Application;
use App\Models\Escalation;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class EscalateStalledApplications extends Command
{
    protected $signature = 'automation:escalate-stalled-applications';

    protected $description = 'Escalate applications with no workflow activity past the configured threshold.';

    public function handle(): int
    {
        $threshold = (int) config('automation.stalled_after_days', 14);
        $cutoff = now()->subDays($threshold);
        $created = 0;

        Application::query()
            ->with('student:id')
            ->where('workflow_state', 'in_progress')
            ->where('updated_at', '<=', $cutoff)
            ->whereDoesntHave('escalations', function ($query): void {
                $query->whereIn('status', ['open', 'in_progress']);
            })
            ->chunkById(100, function ($applications) use (&$created): void {
                foreach ($applications as $application) {
                    $daysStalled = $application->updated_at->diffInDays(now());
                    $level = match (true) {
                        $daysStalled >= 30 => 'critical',
                        $daysStalled >= 21 => 'high',
                        default => 'medium',
                    };

                    $escalation = Escalation::create([
                        'application_id' => $application->id,
                        'student_id' => $application->student_id,
                        'escalation_reason' => "No workflow activity for {$daysStalled} days.",
                        'escalation_level' => $level,
                        'status' => 'open',
                        'days_stalled' => $daysStalled,
                        'escalated_at' => now(),
                    ]);

                    Log::warning('automation.stalled_application_escalated', [
                        'escalation_id' => $escalation->id,
                        'application_id' => $application->id,
                        'days_stalled' => $daysStalled,
                        'escalation_level' => $level,
                    ]);
                    $created++;
                }
            });

        $this->info("Created {$created} stalled-application escalation(s).");

        return self::SUCCESS;
    }
}
