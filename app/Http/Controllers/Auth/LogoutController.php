<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LogoutController extends Controller
{
    /**
     * Log the user out of the application.
     *
     * This method:
     * - Logs out the authenticated user.
     * - Invalidates the current session to prevent reuse.
     * - Regenerates the CSRF token to protect against CSRF attacks.
     * - Redirects the user back to the login page with a success message.
     */
    public function logout(Request $request)
    {
        // Log out the authenticated user.
        Auth::logout();

        // Invalidate the current session to prevent session fixation or reuse.
        $request->session()->invalidate();

        // Regenerate the CSRF token for added security.
        $request->session()->regenerateToken();

        // Redirect to login route with a success flash message.
        return redirect()->route('login')
            ->withSuccess('You have logged out successfully!');
    }
}
