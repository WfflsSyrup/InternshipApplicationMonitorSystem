<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller as BaseController;
use Illuminate\Validation\ValidationException;

class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;

    protected function ensureOnlyInputKeys(Request $request, array $allowed): void
    {
        $unexpected = array_diff(array_keys($request->all()), $allowed);

        if ($unexpected !== []) {
            throw ValidationException::withMessages([
                'request' => ['The request contains unsupported fields.'],
            ]);
        }
    }
}
