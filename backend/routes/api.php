<?php

use App\Http\Controllers\Api\ApplicationController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AutomationController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json(['status' => 'ok']));

Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', fn (Request $request) => response()->json([
        'id' => $request->user()->id,
        'name' => $request->user()->name,
        'role' => $request->user()->role,
    ]));

    Route::middleware('role:coordinator,adviser')->prefix('automation')->group(function () {
        Route::get('/reminders', [AutomationController::class, 'getReminders']);
        Route::get('/incomplete-records', [AutomationController::class, 'getIncompleteRecords']);
        Route::get('/escalations', [AutomationController::class, 'getEscalations']);
        Route::get('/weekly-summary', [AutomationController::class, 'getWeeklySummary']);
    });

    Route::get('/applications', [ApplicationController::class, 'index']);
    Route::patch('/applications/{application}/workflow', [ApplicationController::class, 'updateWorkflow'])
        ->middleware('role:coordinator,adviser,partner_reviewer');
    Route::patch('/milestones/{milestone}/complete', [ApplicationController::class, 'completeMilestone'])
        ->middleware('role:coordinator,adviser');
    Route::patch('/incomplete-records/{record}/resolve', [ApplicationController::class, 'resolveIncompleteRecord'])
        ->middleware('role:coordinator,adviser');
});
