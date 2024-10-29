const std = @import("std");

pub fn main() !void {
    // allocator stuff
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // input arguments
    var cli_args = std.process.args();
    _ = cli_args.next(); // skip first argument (noughtify)
    const pathname = cli_args.next().?; // path to folder to watcha
    const zig = cli_args.next().?; // path to zig bin, needed because I use alias

    // arguments for running another process
    const args = [_][]const u8 {
        zig,
        "build",
        "run",
    };

    const clear_args = [_][]const u8 {
        "clear"
    };

    std.debug.print("Watching {s}\n", .{pathname});

    const fd = try std.posix.inotify_init1(0);
    defer std.posix.close(fd);
    var wd = try std.posix.inotify_add_watch(fd, pathname, std.os.linux.IN.MODIFY);
    defer std.posix.close(wd);
    var buf: [1024]u8 = undefined;
    while (true) {
        const bytes_read = try std.posix.read(fd, &buf);
        if (bytes_read > 0) {
            wd = try std.posix.inotify_add_watch(fd, pathname, std.os.linux.IN.MODIFY);

            var clear = std.process.Child.init(&clear_args, allocator);
            _ = try clear.spawn();
            _ = try clear.wait();

            var build_run = std.process.Child.init(&args, allocator);
            _ = try build_run.spawn();
            _ = try build_run.wait();
        }
    }
}
