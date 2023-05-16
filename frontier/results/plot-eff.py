#!/usr/bin/env python3

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import sys
import math
import shutil
from matplotlib.transforms import ScaledTranslation
#from tol_colors import tol_cmap, tol_cset


matplotlib.use("pgf")
matplotlib.rcParams.update(
    {
        # Adjust to your LaTex-Engine
        "pgf.texsystem": "pdflatex",
        "font.family": "serif",
        "text.usetex": True,
        "pgf.rcfonts": False,
        "axes.unicode_minus": False,
    }
)

factor = 1/2
width = 5.90666*1.2
height = 5.90666*1.2
matplotlib.rcParams['figure.figsize'] = (width, height)  # Use the values from \printsizes
# matplotlib.rc('legend',fontsize=4) # using a size in points

solver = ['ginkgo_GMRES', 'magma_direct']
mechanisms = ['dodecane_lu_qss', 'dodecane_lu']

def collect_all_solver_data(sname,mechname):
    """
    """
    colnames = ['psize', 'bsize', 'ntasks', 'min', 'avg', 'max']

    fname = 'data/' + mechname + '_' + sname + '_scaling.csv'
    df = pd.read_csv(fname)
    return df

opts = { \
         "marklist" : ['o', 'x', '+', '^', 'v', '<', '>', 'd'],
         "colorlist" : ['mediumblue', 'red', 'forestgreen', 'darkmagenta', 'm', 'c', 'pink','k'],
         "linetype" : ['-', '--', '-.', ':', '--', '-.', '--',':'],
         "linewidth" : 0.75,
         "marksize" : [3,3,3,3,3,3,3],
         "markedgewidth" : 1 \
         }


# df.index = range(len(df))

idat=0

for mech in mechanisms:
    df1 = collect_all_solver_data(solver[0], mech)
    df1 = df1.rename(columns={'avg': solver[0]})
    df2 = collect_all_solver_data(solver[1], mech)

    df = df1
    df['magma_direct'] = df2['avg']
    df['magma-eff'] = 100* df['magma_direct'][0]/df['magma_direct']
    df['gmres-eff'] = 100* df['ginkgo_GMRES'][0]/df['ginkgo_GMRES']
    print(df)

    fig, ax = plt.subplots()

    plot_vars =  ['gmres-eff', 'magma-eff']#list(map(lambda x: x + '-avg', solver))

    cycler = plt.cycler(linestyle=opts['linetype'], color=opts['colorlist'], marker=opts['marklist'])
    ax.set_prop_cycle(cycler)
    df.plot(y = plot_vars,ax=ax,
                   x = 'ntasks', xlabel="Num GCDs", ylabel="Parallel efficiency")
    idat = idat +1
    plt.gcf().set_size_inches(width * factor, height * factor)
    plt.tight_layout()
    # plt.yscale("log")
    # plt.setp(plt.gca().get_xticklabels(), rotation=70, ha='right', rotation_mode='anchor', fontsize=8)
    plt.xscale("log")

    leg_solver=['ginkgo-GMRES', 'magma']
    plt.legend(leg_solver)
    plt.grid(True, linestyle='--', linewidth=0.3)

    fname = 'pele_' + mech + '_frontier_weak_scaling_eff.pdf'

    plt.savefig(fname, bbox_inches='tight')
