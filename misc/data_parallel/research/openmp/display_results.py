#!/usr/bin/env python3
from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import subprocess

results_dir = Path.cwd() / "example_output" / "data" / "out"


def get_airfoil() -> pd.DataFrame:
    foil_geom_path = results_dir / "airfoil.csv"
    df = pd.read_csv(foil_geom_path)
    # Close the path:
    first = df.values[0]
    first_df = pd.DataFrame({df.columns[0]: [first[0]], df.columns[1]: [first[1]]})
    result = df.append(first_df)
    return result


def get_net_force(i: int) -> np.ndarray:
    force_path = results_dir / f"net_force_{i:04d}.csv"
    # -1 because my frame of reference is wrong in the Swift code.
    result = pd.read_csv(force_path).values[0, ] * -1.0
    return result


def generate_png(i: int, result_path: Path, airfoil: pd.DataFrame) -> None:
    # figsize is image dimensions in inches
    # dpi is dots/inc, defaulting to 100.
    w_fig_pix = 1280
    h_fix_pix = 720
    dpi = 150.0
    figsize = (w_fig_pix / dpi, h_fix_pix / dpi)
    f = plt.figure(figsize=figsize, dpi=dpi)
    plt.xlim(0, 128)
    plt.ylim(0, 72)

    # Draw the particles
    df = pd.read_csv(result_path)
    xvals = df["X"].values
    yvals = df["Y"].values
    # vxvals = df["VX"].values
    # vyvals = df["VY"].values

    fig = plt.scatter(xvals, yvals, c="#00aaff", s=0.5, marker=".")

    # Overlay the net force, anchored on the first point.
    # And scaled.  A lot.
    force = get_net_force(i) * 5
    x0 = airfoil.X.values[0]
    y0 = airfoil.Y.values[0]
    xf = x0 + force[0]
    yf = y0 + force[1]
    plt.plot([x0, xf], [y0, yf], linewidth=0.5, color="#556688")

    # Overlay the airfoil:
    plt.plot(
        airfoil.X.values, airfoil.Y.values, color="black", linewidth=0.5
    )
    plt.fill(
        airfoil.X.values, airfoil.Y.values, color="#aabbdd"
    )

    plt.axis("off")
    # Ditch the margins
    plt.margins(0.0)
    # Ensure generated PNG names have consecutive indices, to satisfy
    # ffmpeg.
    out_path = results_dir / f"frame_{i:04d}.png"
    # Try again to get the saved image to have the desired size
    # (9.6, 5.4) @ 100 dpi does not result in 960x540 px
    plt.tight_layout(pad=0.0, h_pad=0.0, w_pad=0.0, rect=(0, 0, 1, 1))
    f.savefig(out_path, bbox_inches="tight", pad_inches=0)

    plt.close("all")


def make_movie() -> None:
    # Convert PNGs to an animation at, e.g., 10 fps
    # https://stackoverflow.com/a/13591474/2826337
    # https://unix.stackexchange.com/a/86945
    # The usage is really difficult to sort out -- in particular,
    # the pattern for "-i".

    # For H.264 settings see https://trac.ffmpeg.org/wiki/Encode/H.264
    # and https://trac.ffmpeg.org/wiki/Encode/H.264
    movie_path = Path.cwd() / "movie.mp4"
    args = [
        "ffmpeg", "-r", "30",
        "-i", "frame_%04d.png", "-c:v", "libx264",
        # for Quicktime:
        "-pix_fmt", "yuv420p",
        "-tune", "animation",
        "-preset", "slow",
        "-y", str(movie_path)]
    subprocess.check_call(args, cwd=results_dir)


def main():
    plt.close("all")
    airfoil = get_airfoil()

    csvs = sorted(results_dir.glob("positions_*.csv"))
    for i, result_path in enumerate(csvs, start=1):
        generate_png(i, result_path, airfoil)
    make_movie()

if __name__ == "__main__":
    main()
