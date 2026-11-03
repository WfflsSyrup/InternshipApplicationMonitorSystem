<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\AutomationController;

Route::get('/health', fn () => response()->json(['status' => 'ok']));

Route::prefix('automation')->group(function () {
    Route::get('/reminders', [AutomationController::class, 'getReminders']);
    Route::get('/incomplete-records', [AutomationController::class, 'getIncompleteRecords']);
    Route::get('/escalations', [AutomationController::class, 'getEscalations']);
    Route::get('/weekly-summary', [AutomationController::class, 'getWeeklySummary']);
});

Route::get('/applications', [ApplicationController::class, 'index']);
Route::patch('/applications/{application}/workflow', [ApplicationController::class, 'updateWorkflow']);
Route::patch('/milestones/{milestone}/complete', [ApplicationController::class, 'completeMilestone']);
Route::patch('/incomplete-records/{record}/resolve', [ApplicationController::class, 'resolveIncompleteRecord']);
