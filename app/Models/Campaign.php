<?php

namespace App\Models;

use App\Models\Category;
use App\Models\User;
use App\Models\Comment;
use App\Models\Transaction;
use App\Models\CampaignUpdate;
use App\Models\Resource;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Campaign extends Model
{
    protected $table = 'campaign';

    public $timestamps = false;

    protected $fillable = [
        'name',
        'description',
        'funded',
        'goal',
        'start_date',
        'end_date',
        'close_date',
        'state',
        'category_id',
    ];

    protected $casts = [
        'funded' => 'decimal:2',
        'goal' => 'decimal:2',
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'close_date' => 'datetime',
    ];



    public function category(): BelongsTo { return $this->belongsTo(Category::class);}

    public function collaborators(): BelongsToMany{
        return $this->belongsToMany(
            User::class,
            'campaign_collaborator',
            'campaign_id',
            'user_id'
        );
    }

    public function followers(): BelongsToMany{
        return $this->belongsToMany(
            User::class,
            'campaign_follower',
            'campaign_id',
            'user_id'
        );
    }

    public function comments(): HasMany {return $this->hasMany(Comment::class);}

    public function transactions(): HasMany {return $this->hasMany(Transaction::class);}

    public function updates(): HasMany {return $this->hasMany(CampaignUpdate::class);}

    public function resources(): HasMany { return $this->hasMany(Resource::class);}

}
