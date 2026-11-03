<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('applications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('users')->onDelete('cascade');
            $table->string('application_number')->unique();
            $table->enum('status', [
                'application',
                'verification',
                'endorsement',
                'partner_submission',
                'interview',
                'placement_confirmation',
            ])->default('application');
            $table->enum('workflow_state', ['pending', 'in_progress', 'approved', 'rejected', 'stalled'])->default('pending');
            $table->enum('interview_status', ['not_scheduled', 'scheduled', 'completed', 'offer_received', 'declined'])
                ->default('not_scheduled');
            $table->timestamp('interview_scheduled_at')->nullable();
            $table->timestamp('offer_received_at')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->string('company_name')->nullable();
            $table->string('position')->nullable();
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->text('requirements')->nullable();
            $table->foreignId('coordinator_id')->nullable()->constrained('users');
            $table->foreignId('adviser_id')->nullable()->constrained('users');
            $table->foreignId('partner_id')->nullable()->constrained('users');
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->timestamp('endorsed_at')->nullable();
            $table->timestamp('partner_submitted_at')->nullable();
            $table->timestamp('confirmed_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('applications');
    }
};
