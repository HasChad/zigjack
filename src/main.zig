const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

const CARD_WIDTH = 74;
const CARD_HEIGHT = 104;

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
const Game = struct {
    oppo: std.ArrayList(Card),
    oppo_count: i16,
    player: std.ArrayList(Card),
    player_count: i16,
    turn: Turn,
    state: State,
};

const Textures = struct {
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

    var game = Game{
        .oppo = .empty,
        .oppo_count = 0,
        .player = .empty,
        .player_count = 0,
        .turn = Turn.Player,
        .state = State.Play,
    };
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

        game.oppo_count = 0;
        for (game.oppo.items) |card| {
            const addition = if (card.rank == Rank.J or card.rank == Rank.Q or card.rank == Rank.K) 10 else @intFromEnum(card.rank) + 1;

            game.oppo_count += addition;
        }
        game.player_count = 0;
        for (game.player.items) |card| {
            const addition = if (card.rank == Rank.J or card.rank == Rank.Q or card.rank == Rank.K) 10 else @intFromEnum(card.rank) + 1;

            game.player_count += addition;
        }

        // Draw --------------------------------
        render(game, textures);
    }
}

fn render(game: Game, textures: Textures) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(.black);
    rl.drawTexture(
        textures.table,
        SCREEN_WIDTH / 2 - @divFloor(textures.table.width, 2),
        SCREEN_HEIGHT / 2 - @divFloor(textures.table.height, 2),
        .white,
    );

    // opponent cards
    var total_width = CARD_WIDTH * game.oppo.items.len + (10 * (game.oppo.items.len - 1));
    for (game.oppo.items, 0..) |card, index| {
        rl.drawTextureRec(
            textures.cards,
            if (game.turn == .Player and index == 1) rl.Rectangle.init(
                (CARD_WIDTH * 0),
                (CARD_HEIGHT * 4),
                CARD_WIDTH,
                CARD_HEIGHT,
            ) else rl.Rectangle.init(
                (CARD_WIDTH * @as(f32, @intFromEnum(card.rank))),
                (CARD_HEIGHT * @as(f32, @intFromEnum(card.shape))),
                CARD_WIDTH,
                CARD_HEIGHT,
            ),
            rl.Vector2.init(
                @as(f32, @floatFromInt(SCREEN_WIDTH / 2 - total_width / 2)) + (CARD_WIDTH + 10) * @as(f32, @floatFromInt(index)),
                50,
            ),
            .white,
        );
    }
    var buf: [50]u8 = undefined;
    var text = std.fmt.bufPrintZ(&buf, "{d}", .{game.oppo_count}) catch unreachable;

    rl.drawText(
        text,
        100,
        50,
        30,
        .black,
    );

    // player cards
    total_width = CARD_WIDTH * game.player.items.len + (10 * (game.player.items.len - 1));
    for (game.player.items, 0..) |card, index| {
        rl.drawTextureRec(
            textures.cards,
            rl.Rectangle.init(
                (CARD_WIDTH * @as(f32, @intFromEnum(card.rank))),
                (CARD_HEIGHT * @as(f32, @intFromEnum(card.shape))),
                CARD_WIDTH,
                CARD_HEIGHT,
            ),
            rl.Vector2.init(
                @as(f32, @floatFromInt(SCREEN_WIDTH / 2 - total_width / 2)) + (CARD_WIDTH + 10) * @as(f32, @floatFromInt(index)),
                SCREEN_HEIGHT - CARD_HEIGHT - 50,
            ),
            .white,
        );
    }

    text = std.fmt.bufPrintZ(&buf, "{d}", .{game.player_count}) catch unreachable;
    rl.drawText(
        text,
        100,
        SCREEN_HEIGHT - 50,
        30,
        .black,
    );

    // const text = "Welcome to ZigJack";
    // const size = rl.measureText(text, 30);
    // rl.drawText(
    //     text,
    //     SCREEN_WIDTH / 2 - @divExact(size, 2),
    //     190,
    //     30,
    //     .black,
    // );
}
