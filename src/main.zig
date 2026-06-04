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

const Game = struct {
    oppo: std.ArrayList(Card),
    player: std.ArrayList(Card),
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
        .player = .empty,
    };
    defer game.oppo.deinit(allocator);
    defer game.player.deinit(allocator);

    var card = Card.new(rand);
    try game.oppo.append(allocator, card);
    card = Card.new(rand);
    try game.oppo.append(allocator, card);
    card = Card.new(rand);
    try game.oppo.append(allocator, card);

    card = Card.new(rand);
    try game.player.append(allocator, card);
    card = Card.new(rand);
    try game.player.append(allocator, card);

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
            card = Card.new(rand);
            try game.player.append(allocator, card);
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
            rl.Rectangle.init(
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
