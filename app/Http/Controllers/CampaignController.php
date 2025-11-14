<?php

namespace App\Http\Controllers;

use App\Models\Campaign;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class CampaignController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->query('q');
        $state = $request->query('state');
        $query = Campaign::with('category');

        if (!empty($search)) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ILIKE', '%' . $search . '%')
                    ->orWhere('description', 'ILIKE', '%' . $search . '%');
            });
        }

        if (!empty($state)) {
            $query->where('state', $state);
        }

        $campaigns = $query
            ->orderByDesc('start_date')
            ->paginate(12)
            ->withQueryString();

        return view('pages.campaigns', ['campaigns' => $campaigns, 'search' => $search, 'state' => $state]);
    }

    public function show(Campaign $campaign)
    {
        $campaign->load([
            'category',
            'collaborators',
            'followers',
            'comments',
            'transactions',
            'updates',
            'resources',
        ]);

        return view('pages.campaign', [
            'campaign' => $campaign,
        ]);
    }


    public function create()
    {
        // add policies later
        $categories = Category::orderBy('name')->get();
        return view('pages.campaign_create', ['categories' => $categories]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'goal' => 'required|numeric|min:0.01',
            'end_date' => 'nullable|date',
            'close_date' => 'nullable|date',
            'category_id' => 'required|integer|exists:category,id',
        ]);

        $data['funded'] = 0;
        $data['start_date'] = now();
        $data['state'] = 'unfunded';

        $campaign = Campaign::create($data);

        if (Auth::check()) {
            $campaign->collaborators()->attach(Auth::id());
        }

        return redirect()->route('campaigns.show', $campaign);
    }


    public function edit(Campaign $campaign)
    {
        // add policie later
        $categories = Category::orderBy('name')->get();
        return view('pages.campaign_edit', ['campaign' => $campaign, 'categories' => $categories,]);
    }
    
    public function update(Request $request, Campaign $campaign)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'goal' => 'required|numeric|min:0.01',
            'end_date' => 'nullable|date',
            'close_date' => 'nullable|date',
            'category_id' => 'required|integer|exists:category,id',
        ]);

        $data['end_date'] = $data['end_date'] ?? null;
        $data['close_date'] = $data['close_date'] ?? null;

        $campaign->update($data);

        return redirect()
            ->route('campaigns.show', $campaign)
            ->with('success', 'Campaign updated successfully!');
    }

}
