<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('weekly_summaries', function (Blueprint $table) {
            $table->id();
            $table->string('week_label');
            $table->date('week_start')->unique();
            $table->date('week_end');
            $table->integer('total_applications')->default(0);
            $table->integer('applications_submitted')->default(0);
            $table->integer('applications_reviewed')->default(0);
            $table->integer('interviews_scheduled')->default(0);
            $table->integer('offers_received')->default(0);
            $table->integer('placements_confirmed')->default(0);
            $table->integer('rejected')->default(0);
            $table->integer('pending_review')->default(0);
            $table->decimal('placement_rate', 5, 2)->default(0.00);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('weekly_summaries');
    }
};
