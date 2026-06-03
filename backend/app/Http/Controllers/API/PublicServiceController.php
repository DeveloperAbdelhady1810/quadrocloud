<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Mail\ServiceRequestMail;
use App\Models\ServiceCatalog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class PublicServiceController extends Controller
{
    public function index()
    {
        $services = ServiceCatalog::where('is_active', true)
            ->where('is_public', true)
            ->get()
            ->map(fn($s) => [
                'id'          => $s->id,
                'name'        => $s->name,
                'description' => $s->description,
                'icon'        => $s->icon,
                'image_path'  => $s->image_path,
                'price'       => $s->show_price ? (float) $s->default_price : null,
                'show_price'  => $s->show_price,
            ]);
        return response()->json($services);
    }

    public function request(Request $request, ServiceCatalog $service)
    {
        $data = $request->validate([
            'name'    => 'required|string|max:100',
            'email'   => 'required|email',
            'phone'   => 'required|string|max:20',
            'message' => 'nullable|string|max:1000',
        ]);

        $mail = new ServiceRequestMail(
            serviceName:  $service->name,
            senderName:   $data['name'],
            senderEmail:  $data['email'],
            senderPhone:  $data['phone'],
            message:      $data['message'] ?? '',
        );

        Mail::to(['ahmedabdelhady@quadrocloud.net', 'abdelrahmansamy@quadrocloud.net'])
            ->send($mail);

        return response()->json(['message' => 'تم إرسال طلبك بنجاح']);
    }
}
