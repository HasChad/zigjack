const std = @import("std");
const rl = @import("raylib");
const main = @import("main.zig");
const Game = main.Game;
const Textures = main.Textures;
const CARD_HEIGHT = main.CARD_HEIGHT;
const CARD_WIDTH = main.CARD_WIDTH;
const SCREEN_HEIGHT = main.SCREEN_HEIGHT;
const SCREEN_WIDTH = main.SCREEN_WIDTH;

pub fn renderPlay(game: Game, textures: Textures) void {
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

    var buf: [50]u8 = undefined;
    var text = std.fmt.bufPrintZ(&buf, "{d}", .{game.oppo_count}) catch unreachable;
    rl.drawText(
        text,
        100,
        50,
        30,
        .black,
    );

    text = std.fmt.bufPrintZ(&buf, "{d}", .{game.player_count}) catch unreachable;
    rl.drawText(
        text,
        100,
        SCREEN_HEIGHT - 80,
        30,
        .black,
    );

    text = std.fmt.bufPrintZ(&buf, "turn: {}", .{game.turn}) catch unreachable;
    rl.drawText(
        text,
        SCREEN_WIDTH / 2,
        SCREEN_HEIGHT / 2 - 30,
        30,
        .black,
    );

    text = std.fmt.bufPrintZ(&buf, "state: {}", .{game.state}) catch unreachable;
    rl.drawText(
        text,
        SCREEN_WIDTH / 2,
        SCREEN_HEIGHT / 2,
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
