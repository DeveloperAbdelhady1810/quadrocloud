<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use App\Models\Post;
use Illuminate\Http\Request;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::with('creator')->orderByDesc('created_at')->paginate(20);
        return view('dashboard.posts.index', compact('posts'));
    }

    public function create()
    {
        return view('dashboard.posts.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title'      => 'required|string|max:255',
            'content'    => 'required|string',
            'media'      => 'nullable|file|mimes:jpg,jpeg,png,gif,webp,mp4,mov|max:51200',
            'is_published' => 'boolean',
        ]);

        $mediaPath = null;
        $mediaType = null;
        if ($request->hasFile('media')) {
            $file = $request->file('media');
            $mediaPath = $file->store('posts', 'public');
            $mediaType = str_starts_with($file->getMimeType(), 'video') ? 'video' : 'image';
        }

        Post::create([
            'title'        => $data['title'],
            'content'      => $data['content'],
            'media_path'   => $mediaPath,
            'media_type'   => $mediaType,
            'is_published' => $request->boolean('is_published'),
            'published_at' => $request->boolean('is_published') ? now() : null,
            'created_by'   => auth()->id(),
        ]);

        return redirect()->route('dashboard.posts.index')->with('success', 'تم نشر المقال');
    }

    public function edit(Post $post)
    {
        return view('dashboard.posts.edit', compact('post'));
    }

    public function update(Request $request, Post $post)
    {
        $data = $request->validate([
            'title'        => 'required|string|max:255',
            'content'      => 'required|string',
            'media'        => 'nullable|file|mimes:jpg,jpeg,png,gif,webp,mp4,mov|max:51200',
            'is_published' => 'boolean',
        ]);

        $mediaPath = $post->media_path;
        $mediaType = $post->media_type;
        if ($request->hasFile('media')) {
            $file = $request->file('media');
            $mediaPath = $file->store('posts', 'public');
            $mediaType = str_starts_with($file->getMimeType(), 'video') ? 'video' : 'image';
        }

        $wasPublished = $post->is_published;
        $post->update([
            'title'        => $data['title'],
            'content'      => $data['content'],
            'media_path'   => $mediaPath,
            'media_type'   => $mediaType,
            'is_published' => $request->boolean('is_published'),
            'published_at' => (!$wasPublished && $request->boolean('is_published')) ? now() : $post->published_at,
        ]);

        return redirect()->route('dashboard.posts.index')->with('success', 'تم تحديث المقال');
    }

    public function destroy(Post $post)
    {
        $post->delete();
        return back()->with('success', 'تم حذف المقال');
    }
}
