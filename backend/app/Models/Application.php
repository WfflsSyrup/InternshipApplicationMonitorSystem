<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Application extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'application_number',
        'status',
        'workflow_state',
        'company_name',
        'position',
        'start_date',
        'end_date',
        'requirements',
        'coordinator_id',
        'adviser_id',
        'partner_id',
        'submitted_at',
        'verified_at',
        'endorsed_at',
        'partner_submitted_at',
        'interview_scheduled_at',
        'offer_received_at',
        'rejected_at',
        'confirmed_at',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'submitted_at' => 'datetime',
        'verified_at' => 'datetime',
        'endorsed_at' => 'datetime',
        'partner_submitted_at' => 'datetime',
        'interview_scheduled_at' => 'datetime',
        'offer_received_at' => 'datetime',
        'rejected_at' => 'datetime',
        'confirmed_at' => 'datetime',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function coordinator()
    {
        return $this->belongsTo(User::class, 'coordinator_id');
    }

    public function adviser()
    {
        return $this->belongsTo(User::class, 'adviser_id');
    }

    public function partner()
    {
        return $this->belongsTo(User::class, 'partner_id');
    }

    public function milestones()
    {
        return $this->hasMany(Milestone::class);
    }

    public function incompleteRecords()
    {
        return $this->hasMany(IncompleteRecord::class);
    }

    public function escalations()
    {
        return $this->hasMany(Escalation::class);
    }
}
