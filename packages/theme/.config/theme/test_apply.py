"""Tests for theme-apply. Run: python3 -m unittest test_apply.py (from this folder)."""
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
SCRIPT = HERE.parent.parent / ".local" / "bin" / "theme-apply"
OUTPUTS = ["current.json", "foot.ini", "sway.conf", "gtk.css", "qt6ct.conf",
           "gtklock.css", "nvim.lua", "btop.theme"]


class ThemeApplyTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.home = self.tmp / "theme"
        shutil.copytree(HERE / "palettes", self.home / "palettes")
        shutil.copytree(HERE / "templates", self.home / "templates")
        self.cache = self.tmp / "cache"
        self.walls = self.tmp / "walls"
        self.env = dict(os.environ, THEME_HOME=str(self.home), THEME_WALL_DIR=str(self.walls),
                        THEME_CACHE=str(self.cache), THEME_DRY="1")

    def tearDown(self):
        shutil.rmtree(self.tmp)

    def run_apply(self, *args, env=None):
        return subprocess.run([str(SCRIPT), *args], env=env or self.env,
                              capture_output=True, text=True)

    def current(self):
        return json.loads((self.cache / "current.json").read_text())

    def test_list_returns_all_themes(self):
        r = self.run_apply("--list")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(r.stdout.split(), sorted(p.stem for p in (HERE / "palettes").glob("*.json")))
        self.assertIn("gruvbox-retro", r.stdout.split())

    def test_apply_writes_all_fragments(self):
        r = self.run_apply("gruvbox-light")
        self.assertEqual(r.returncode, 0, r.stderr)
        for name in OUTPUTS:
            self.assertTrue((self.cache / name).exists(), name)
        self.assertEqual(self.current()["name"], "gruvbox-light")

    def test_template_substitution(self):
        self.run_apply("rose-pine")
        sway = (self.cache / "sway.conf").read_text()
        self.assertIn("#ebbcba", sway)
        self.assertNotIn("$", sway)
        foot = (self.cache / "foot.ini").read_text()
        self.assertIn("background=191724", foot)  # darkest bg (bg0)
        self.assertIn("alpha=0.82", foot)

    def test_light_theme_terminal_keeps_light_background(self):
        self.run_apply("gruvbox-light")
        foot = (self.cache / "foot.ini").read_text()
        self.assertIn("background=fbf1c7", foot)  # bg1: on light themes the darker of bg0/bg1

    def test_ansi_derived_when_palette_has_none(self):
        p = self.home / "palettes" / "rose-pine.json"
        data = json.loads(p.read_text())
        del data["ansi"]
        p.write_text(json.dumps(data))
        r = self.run_apply("rose-pine")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("regular1=eb6f92", (self.cache / "foot.ini").read_text())  # red

    def test_missing_key_writes_nothing(self):
        p = self.home / "palettes" / "rose-pine.json"
        data = json.loads(p.read_text())
        del data["accent"]
        p.write_text(json.dumps(data))
        r = self.run_apply("rose-pine")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("accent", r.stderr)
        self.assertFalse(self.cache.exists() and any(self.cache.iterdir()))

    def test_unknown_theme_fails(self):
        r = self.run_apply("no-such-theme")
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("no-such-theme", r.stderr)

    def test_previous_reverts(self):
        self.run_apply("rose-pine")
        self.run_apply("gruvbox-light")
        r = self.run_apply("--previous")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(self.current()["name"], "rose-pine")

    def test_bad_wallpaper_keeps_theme(self):
        self.run_apply("rose-pine")
        r = self.run_apply("--wallpaper", "/nonexistent.png")
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(self.current()["name"], "rose-pine")

    def test_set_wallpaper_keeps_theme(self):
        self.run_apply("rose-pine")
        img = self.tmp / "w.png"
        img.write_bytes(b"x")
        r = self.run_apply("--set-wallpaper", str(img))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(self.current()["name"], "rose-pine")
        self.assertNotEqual(self.run_apply("--set-wallpaper", "/nope.png").returncode, 0)

    def make_walls(self, theme, names):
        d = self.walls / theme
        d.mkdir(parents=True, exist_ok=True)
        for n in names:
            (d / n).write_bytes(b"x")
        return d

    def test_theme_never_picks_a_wallpaper_by_itself(self):
        self.make_walls("rose-pine", ["b.png", "a.jpg", "notes.txt"])
        self.run_apply("rose-pine")
        self.assertIsNone(self.current()["wallpaper"])

    def test_theme_without_folder_keeps_wallpaper(self):
        self.run_apply("rose-pine")
        self.assertIsNone(self.current()["wallpaper"])

    def test_chosen_wallpaper_is_remembered_per_theme(self):
        d = self.make_walls("rose-pine", ["a.png", "b.png"])
        self.run_apply("rose-pine")
        r = self.run_apply("--set-wallpaper", str(d / "b.png"))
        self.assertEqual(r.returncode, 0, r.stderr)
        self.run_apply("gruvbox-light")
        self.run_apply("rose-pine")
        self.assertEqual(self.current()["wallpaper"], str(d / "b.png"))

    def test_walls_lists_each_theme(self):
        d = self.make_walls("rose-pine", ["a.png"])
        r = self.run_apply("--walls")
        data = json.loads(r.stdout)
        self.assertEqual(data["rose-pine"], str(d / "a.png"))
        self.assertIsNone(data["gruvbox-light"])
        self.assertEqual(len(data), len(list((HERE / "palettes").glob("*.json"))))

    def test_reload_commands_missing_is_ok(self):
        # empty PATH: swaymsg, gsettings, swaybg all missing; must still succeed
        env = dict(self.env, PATH=str(self.tmp), THEME_NO_PTY="1",
                   THEME_BTOP_CONF=str(self.tmp / "btop.conf"))
        del env["THEME_DRY"]
        r = subprocess.run([shutil.which("python3"), str(SCRIPT), "rose-pine"],
                           env=env, capture_output=True, text=True)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertEqual(self.current()["name"], "rose-pine")


if __name__ == "__main__":
    unittest.main()
