const std = @import("std");
const rl = @import("raylib");
const render = @import("render.zig");

pub const SCREEN_WIDTH = 800;
pub const SCREEN_HEIGHT = 450;

pub const CARD_WIDTH = 74;
pub const CARD_HEIGHT = 104;

const Shape = enum { Spade, Club, Heart, Diamond };
const Rank = enum { A, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, J, Q, K };
const Card = struct {
    shape: Shape,
    rank: Rank,
    pos: rl.Vector2,

    fn new(rnd: std.Random) Card {
        return Card{
            .rank = rnd.enumValue(Rank),
            .shape = rnd.enumValue(Shape),
            .pos = rl.Vector2.zero(),
        };
    }
};
const Turn = enum { Player, Table };
const State = enum { Menu, Play, End };
pub const Game = struct {
    oppo: std.ArrayList(Card),
    oppo_count: i16,
    player: std.ArrayList(Card),
    player_count: i16,
    turn: Turn,
    state: State,

    fn new() Game {
        return Game{
            .oppo = .empty,
            .oppo_count = 0,
            .player = .empty,
            .player_count = 0,
            .turn = Turn.Player,
            .state = State.Play,
        };
    }
};

pub const Textures = struct {
    table: rl.Texture2D,
    cards: rl.Texture2D,
    chips: rl.Texture2D,
};

pub fn main() anyerror!void {
    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "ZigJack");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();

    var prng: std.Random.DefaultPrng = .init(undefined);
    const rand = prng.random();

    var game = Game.new();
    defer game.oppo.deinit(allocator);
    defer game.player.deinit(allocator);

    var card_n = Card.new(rand);
    try game.oppo.append(allocator, card_n);
    card_n = Card.new(rand);
    try game.oppo.append(allocator, card_n);

    card_n = Card.new(rand);
    try game.player.append(allocator, card_n);
    card_n = Card.new(rand);
    try game.player.append(allocator, card_n);

    // texture loading
    const table_image = try rl.loadImage("assets/table.png");
    const card_image = try rl.loadImage("assets/card-sheet.png");
    const chip_image = try rl.loadImage("assets/chip-sheet.png");

    const textures = Textures{
        .table = try rl.loadTextureFromImage(table_image),
        .cards = try rl.loadTextureFromImage(card_image),
        .chips = try rl.loadTextureFromImage(chip_image),
    };

    rl.unloadImage(table_image);
    rl.unloadImage(card_image);
    rl.unloadImage(chip_image);

    while (!rl.windowShouldClose()) {
        // Update ------------------------------

        switch (game.state) {
            .Play => {
                if (rl.isMouseButtonPressed(rl.MouseButton.left)) {
                    outer: while (true) {
                        card_n = Card.new(rand);

                        for (game.oppo.items) |card| {
                            if (card.rank == card_n.rank and card.shape == card_n.shape) {
                                continue :outer;
                            }
                        }
                        for (game.player.items) |card| {
                            if (card.rank == card_n.rank and card.shape == card_n.shape) {
                                continue :outer;
                            }
                        }

                        try game.player.append(allocator, card_n);
                        break;
                    }
                }

                if (rl.isMouseButtonPressed(rl.MouseButton.right)) {
                    game.turn = Turn.Table;
                }
            },
            .End => {
                if (rl.isKeyPressed(rl.KeyboardKey.r)) {
                    game = Game.new();
                }
            },
            .Menu => undefined,
        }

        game.oppo_count = 0;
        var contains_ace = false;
        for (game.oppo.items) |card| {
            const addition = if (card.rank == Rank.J or card.rank == Rank.Q or card.rank == Rank.K) 10 else @intFromEnum(card.rank) + 1;

            if (!contains_ace)
                contains_ace = card.rank == Rank.A;

            game.oppo_count += addition;
        }
        if (game.oppo_count <= 11 and contains_ace)
            game.oppo_count += 10;

        contains_ace = false;
        game.player_count = 0;
        for (game.player.items) |card| {
            const addition = if (card.rank == Rank.J or card.rank == Rank.Q or card.rank == Rank.K) 10 else @intFromEnum(card.rank) + 1;

            if (!contains_ace)
                contains_ace = card.rank == Rank.A;

            game.player_count += addition;
        }
        if (game.player_count <= 11 and contains_ace)
            game.player_count += 10;

        // Draw --------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.black);
        rl.drawTexture(
            textures.table,
            SCREEN_WIDTH / 2 - @divFloor(textures.table.width, 2),
            SCREEN_HEIGHT / 2 - @divFloor(textures.table.height, 2),
            .white,
        );

        render.renderPlay(game, textures);
    }
}
