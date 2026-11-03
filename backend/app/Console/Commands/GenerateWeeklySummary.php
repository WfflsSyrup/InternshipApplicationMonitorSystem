<?php

namespace App\Console\Commands;

use App\Models\Application;
use App\Models\WeeklySummary;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

class GenerateWeeklySummary extends Command
{
    protected $signature = 'automation:generate-weekly-summary';

    protected $description = 'Generate a placement summary for the previous full week.';

    public function handle(): int
    {
        $weekStart = Carbon::now()->subWeek()->startOfWeek(Carbon::MONDAY)->startOfDay();
        $weekEnd = $weekStart->copy()->endOfWeek(Carbon::SUNDAY)->endOfDay();
        $createdInWeek = Application::query()->whereBetween('created_at', [$weekStart, $weekEnd]);

        $totalApplications = (clone $createdInWeek)->count();
        $summary = WeeklySummary::updateOrCreate(
            ['week_start' => $weekStart->toDateString()],
            [
                'week_label' => sprintf('Week %d, %d', $weekStart->isoWeek, $weekStart->year),
                'week_end' => $weekEnd->toDateString(),
                'total_applications' => $totalApplications,
                'applications_submitted' => $this->countEvents('submitted_at', $weekStart, $weekEnd),
                'applications_reviewed' => $this->countEvents('verified_at', $weekStart, $weekEnd),
                'interviews_scheduled' => $this->countEvents('interview_scheduled_at', $weekStart, $weekEnd),
                'offers_received' => $this->countEvents('offer_received_at', $weekStart, $weekEnd),
                'placements_confirmed' => $this->countEvents('confirmed_at', $weekStart, $weekEnd),
                'rejected' => $this->countEvents('rejected_at', $weekStart, $weekEnd),
                'pending_review' => (clone $createdInWeek)
                    ->where('status', 'verification')
                    ->whereIn('workflow_state', ['pending', 'in_progress'])
                    ->count(),
                'placement_rate' => $totalApplications === 0
                    ? 0
                    : round(
                        ($this->countEvents('confirmed_at', $weekStart, $weekEnd) / $totalApplications) * 100,
                        2,
                    ),
            ],
        );

        Log::info('automation.weekly_summary_generated', [
            'summary_id' => $summary->id,
            'week_start' => $weekStart->toDateString(),
            'week_end' => $weekEnd->toDateString(),
        ]);
        $this->info("Generated placement summary for {$weekStart->toDateString()}.");

        return self::SUCCESS;
    }

    private function countEvents(string $column, Carbon $start, Carbon $end): int
    {
        return Application::query()->whereBetween($column, [$start, $end])->count();
    }
}
