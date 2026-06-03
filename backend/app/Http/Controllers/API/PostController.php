<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Post;

class PostController extends Controller
{
    public function index()
    {
        $posts = Post::where('is_published', true)
            ->orderByDesc('published_at')
            ->select(['id', 'title', 'content', 'media_path', 'media_type', 'published_at'])
            ->paginate(20);
        return response()->json($posts);
    }

    public function show(Post $post)
    {
        abort_unless($post->is_published, 404);
        return response()->json($post->only(['id', 'title', 'content', 'media_path', 'media_type', 'published_at']));
    }
}
