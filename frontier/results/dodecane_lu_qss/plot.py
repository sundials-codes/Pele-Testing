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
mechanisms = ['dodecane_lu_qss']

def collect_all_solver_data(sname):
    """
    """
    colnames = ['psize', 'bsize', 'ntasks', 'min', 'avg', 'max']

    fname = 'data/dodecane_lu_qss_' + sname + '_scaling.csv'
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

df1 = collect_all_solver_data(solver[0])
df1 = df1.rename(columns={'avg': solver[0]})
df2 = collect_all_solver_data(solver[1])
# df3 = collect_all_solver_data(solver[2])



df = df1
# df['ginkgo_GMRES'] = df2['avg']
df['magma_direct'] = df2['avg']

# df.index = range(len(df))

print(df)
idat=0
leg_solver=['ginkgo-GMRES', 'magma']

for mech in mechanisms:

    fig, ax = plt.subplots()

    plot_vars =  solver #list(map(lambda x: x + '-avg', solver))

    cycler = plt.cycler(linestyle=opts['linetype'], color=opts['colorlist'], marker=opts['marklist'])
    ax.set_prop_cycle(cycler)
    df.plot(y = plot_vars,ax=ax,
                   x = 'ntasks', xlabel="Num GCDs", ylabel="Total time(s)")
    idat = idat +1
    plt.gcf().set_size_inches(width * factor, height * factor)
    plt.tight_layout()
    # plt.yscale("log")
    # plt.setp(plt.gca().get_xticklabels(), rotation=70, ha='right', rotation_mode='anchor', fontsize=8)
    plt.xscale("log")

    plt.legend(leg_solver)
    plt.grid(True, linestyle='--', linewidth=0.3)

    fname = 'pele_' + mech + '_frontier_weak_scaling.pdf'

    plt.savefig(fname, bbox_inches='tight')
    #shutil.copy('./'+fname, '/home/pratik/Documents/10MyPapers/2022-thesis/images/batched-solvers/'+fname)
