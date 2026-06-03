<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use App\Models\ServiceCatalog;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    public function index()
    {
        $services = ServiceCatalog::orderBy('name')->get();
        return view('dashboard.services.index', compact('services'));
    }

    public function create()
    {
        return view('dashboard.services.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'          => 'required|string|max:255',
            'description'   => 'nullable|string',
            'default_price' => 'required|numeric|min:0',
            'show_price'    => 'boolean',
            'is_public'     => 'boolean',
            'is_active'     => 'boolean',
            'icon'          => 'nullable|string|max:10',
            'image'         => 'nullable|file|mimes:jpg,jpeg,png,gif,webp|max:5120',
        ]);

        $imagePath = null;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('services', 'public');
        }

        ServiceCatalog::create([
            'name'          => $data['name'],
            'description'   => $data['description'] ?? null,
            'default_price' => $data['default_price'],
            'show_price'    => $request->boolean('show_price'),
            'is_public'     => $request->boolean('is_public'),
            'is_active'     => $request->boolean('is_active', true),
            'icon'          => $data['icon'] ?? null,
            'image_path'    => $imagePath,
        ]);

        return redirect()->route('dashboard.services.index')->with('success', 'تمت إضافة الخدمة');
    }

    public function edit(ServiceCatalog $service)
    {
        return view('dashboard.services.edit', compact('service'));
    }

    public function update(Request $request, ServiceCatalog $service)
    {
        $data = $request->validate([
            'name'          => 'required|string|max:255',
            'description'   => 'nullable|string',
            'default_price' => 'required|numeric|min:0',
            'show_price'    => 'boolean',
            'is_public'     => 'boolean',
            'is_active'     => 'boolean',
            'icon'          => 'nullable|string|max:10',
            'image'         => 'nullable|file|mimes:jpg,jpeg,png,gif,webp|max:5120',
        ]);

        $imagePath = $service->image_path;
        if ($request->hasFile('image')) {
            $imagePath = $request->file('image')->store('services', 'public');
        }

        $service->update([
            'name'          => $data['name'],
            'description'   => $data['description'] ?? null,
            'default_price' => $data['default_price'],
            'show_price'    => $request->boolean('show_price'),
            'is_public'     => $request->boolean('is_public'),
            'is_active'     => $request->boolean('is_active', true),
            'icon'          => $data['icon'] ?? null,
            'image_path'    => $imagePath,
        ]);

        return redirect()->route('dashboard.services.index')->with('success', 'تم تحديث الخدمة');
    }

    public function destroy(ServiceCatalog $service)
    {
        $service->delete();
        return back()->with('success', 'تم حذف الخدمة');
    }
}
