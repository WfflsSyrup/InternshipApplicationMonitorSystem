<?php

namespace Tests\Feature;

use App\Models\Application;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ApiSecurityTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_rejects_invalid_credentials_without_debug_details(): void
    {
        $user = $this->createUser('coordinator');

        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'incorrect-password',
        ]);

        $response->assertUnauthorized()
            ->assertJsonMissingPath('trace')
            ->assertJsonMissingPath('exception');
    }

    public function test_login_rejects_missing_fields_with_validation_status(): void
    {
        $this->postJson('/api/login', [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'password'])
            ->assertJsonMissingPath('trace');
    }

    public function test_login_rejects_unexpected_input_keys(): void
    {
        $this->postJson('/api/login', [
            'email' => 'user@example.test',
            'password' => 'valid-looking-password',
            'role' => 'coordinator',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['request']);
    }

    public function test_successful_login_returns_minimal_identity_and_stores_only_token_digest(): void
    {
        $user = $this->createUser('coordinator');

        $response = $this->postJson('/api/login', [
            'email' => $user->email,
            'password' => 'A-long-test-password-2026',
        ])->assertOk()
            ->assertJsonStructure(['token', 'user' => ['id', 'name', 'role']])
            ->assertJsonMissingPath('user.email');

        $plainTextToken = $response->json('token');
        $this->assertSame(
            hash('sha256', substr($plainTextToken, strpos($plainTextToken, '|') + 1)),
            $user->tokens()->firstOrFail()->token,
        );
    }

    public function test_altered_bearer_token_is_rejected(): void
    {
        $user = $this->createUser('coordinator');
        $plainTextToken = $user->createToken('test')->plainTextToken;
        $lastCharacter = substr($plainTextToken, -1);
        $alteredToken = substr($plainTextToken, 0, -1).($lastCharacter === 'a' ? 'b' : 'a');

        $this->withToken($alteredToken)
            ->getJson('/api/applications')
            ->assertUnauthorized()
            ->assertJsonMissingPath('trace');
    }

    public function test_expired_bearer_token_is_rejected(): void
    {
        $user = $this->createUser('coordinator');
        $token = $user->createToken('test');
        $token->accessToken->forceFill(['expires_at' => now()->subMinute()])->save();

        $this->withToken($token->plainTextToken)
            ->getJson('/api/applications')
            ->assertUnauthorized()
            ->assertJsonMissingPath('trace');
    }

    public function test_partner_reviewer_cannot_read_coordinator_automation(): void
    {
        $user = $this->createUser('partner_reviewer');

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/automation/weekly-summary')
            ->assertForbidden()
            ->assertJsonMissingPath('trace');
    }

    public function test_student_sees_only_own_minimal_application_data(): void
    {
        $student = $this->createUser('student');
        $anotherStudent = $this->createUser('student');
        $ownApplication = $this->makeApplication($student, 'APP-OWN');
        $this->makeApplication($anotherStudent, 'APP-OTHER');

        $response = $this->actingAs($student, 'sanctum')
            ->getJson('/api/applications')
            ->assertOk();

        $records = $response->json();
        $this->assertCount(1, $records);
        $this->assertSame($ownApplication->id, $records[0]['id']);
        $this->assertArrayNotHasKey('student_name', $records[0]);
        $this->assertArrayNotHasKey('student_id', $records[0]);
    }

    public function test_student_cannot_change_application_workflow(): void
    {
        $student = $this->createUser('student');
        $application = $this->makeApplication($student, 'APP-LOCKED');

        $this->actingAs($student, 'sanctum')
            ->patchJson("/api/applications/{$application->id}/workflow", [
                'stage' => 'verification',
            ])
            ->assertForbidden()
            ->assertJsonMissingPath('trace');
    }

    public function test_partner_reviewer_cannot_access_an_unassigned_application(): void
    {
        $reviewer = $this->createUser('partner_reviewer');
        $student = $this->createUser('student');
        $application = $this->makeApplication($student, 'APP-OUT-OF-SCOPE');

        $this->actingAs($reviewer, 'sanctum')
            ->getJson('/api/applications')
            ->assertOk()
            ->assertExactJson([]);

        $this->actingAs($reviewer, 'sanctum')
            ->patchJson("/api/applications/{$application->id}/workflow", [
                'stage' => 'interview',
            ])
            ->assertNotFound()
            ->assertJsonMissingPath('trace');
    }

    private function createUser(string $role): User
    {
        return User::query()->create([
            'name' => ucfirst($role).' User',
            'email' => uniqid($role.'-', true).'@example.test',
            'password' => Hash::make('A-long-test-password-2026'),
            'role' => $role,
        ]);
    }

    private function makeApplication(User $student, string $number): Application
    {
        return Application::query()->create([
            'student_id' => $student->id,
            'application_number' => $number,
        ]);
    }
}
