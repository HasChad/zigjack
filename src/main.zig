const std = @import("std");
const rl = @import("raylib");

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;

const CARD_WIDTH = 74;
const CARD_HEIGHT = 104;

const Shape = enum { Spade, Club, Heart, Diamond };
const Rank = enum { A, One, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, J, Q, K };
const Card = struct { shape: Shape, rank: Rank, pos: rl.Vector2 };

const Game = struct {
    table: std.ArrayList(Card),
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

    var game = Game{ .table = .empty, .player = .empty };
    defer game.table.deinit(allocator);
    defer game.player.deinit(allocator);

    var card =
        Card{
            .rank = Rank.One,
            .shape = Shape.Club,
            .pos = rl.Vector2.zero(),
        };
    try game.table.append(allocator, card);

    card =
        Card{
            .rank = Rank.K,
            .shape = Shape.Heart,
            .pos = rl.Vector2.zero(),
        };
    try game.table.append(allocator, card);

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

    for (game.table.items, 0..) |card, index| {
        rl.drawTextureRec(
            textures.cards,
            rl.Rectangle.init(
                (CARD_WIDTH * @as(f32, @intFromEnum(card.rank) - 1)),
                (CARD_HEIGHT * @as(f32, @intFromEnum(card.shape) - 1)),
                CARD_WIDTH,
                CARD_HEIGHT,
            ),
            rl.Vector2.init(CARD_WIDTH * @as(f32, @floatFromInt(index)), 100),
            .white,
        );
    }

    const text = "Welcome to ZigJack";
    const size = rl.measureText(text, 30);
    rl.drawText(
        text,
        SCREEN_WIDTH / 2 - @divExact(size, 2),
        190,
        30,
        .black,
    );
}
