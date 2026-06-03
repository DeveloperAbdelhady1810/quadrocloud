<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        $client = \App\Models\Client::where('email', $request->email)->first();

        if (!$client || !\Illuminate\Support\Facades\Hash::check($request->password, $client->password)) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'email' => ['بيانات الدخول غير صحيحة'],
            ]);
        }

        if (!$client->is_active) {
            return response()->json(['message' => 'الحساب غير مفعل، تواصل مع الدعم'], 403);
        }

        $token = $client->createToken('client-app')->plainTextToken;

        return response()->json([
            'token'  => $token,
            'client' => [
                'id'           => $client->id,
                'name'         => $client->name,
                'email'        => $client->email,
                'phone'        => $client->phone,
                'company_name' => $client->company_name,
                'locale'       => $client->locale,
            ],
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'تم تسجيل الخروج']);
    }

    public function profile(Request $request)
    {
        $c = $request->user();
        return response()->json([
            'id'           => $c->id,
            'name'         => $c->name,
            'email'        => $c->email,
            'phone'        => $c->phone,
            'company_name' => $c->company_name,
            'address'      => $c->address,
            'locale'       => $c->locale,
        ]);
    }

    public function updateFcmToken(Request $request)
    {
        $request->validate(['fcm_token' => 'required|string']);
        $request->user()->update(['fcm_token' => $request->fcm_token]);
        return response()->json(['message' => 'FCM token updated']);
    }

    public function updateLocale(Request $request)
    {
        $request->validate(['locale' => 'required|in:ar,en']);
        $request->user()->update(['locale' => $request->locale]);
        return response()->json(['message' => 'Locale updated']);
    }

    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required|string',
            'password'         => 'required|string|min:8|confirmed',
        ]);

        $client = $request->user();

        if (!\Illuminate\Support\Facades\Hash::check($request->current_password, $client->password)) {
            return response()->json(['message' => 'كلمة المرور الحالية غير صحيحة'], 422);
        }

        $client->update(['password' => $request->password]);
        return response()->json(['message' => 'تم تغيير كلمة المرور']);
    }
}
