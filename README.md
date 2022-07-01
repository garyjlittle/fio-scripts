# fio-scripts
* [Cache Finder](#cache-finder-scripts)
 * [Example](#cache-finder-example)
 * [Example-plot](#cache-finder-example-plot) 
### Cache finder scripts
These scripts use increasing WSS to find cache points.  The scripts are split like this

1. `generate-cache-finder.sh` ; generates a set of fio scripts and places them in the directory specified with `-d`
2. `run-cache-finder.sh` ;  runs the fio scripts in the directory specified with `-d`.  Will need sudo.
3. `process-cache-finder.sh` ; processes the output of fio (yaml) and prints a table of results
4. `plot-cache-finder` ; invokes gnuplot to display results.  `plot-cache-finder` can accept multiple directories and will plot the data therein

#### Cache Finder example
```
 ./generate-cache-finder.sh -d /tmp/dellboy -f /dev/nvme0n1 -b 64k -q 64
sudo ./run-cache-finder.sh -d /tmp/dellboy-wss-nvme0n1-64k-64
./process-cache-finder.sh -d /tmp/dellboy-wss-nvme0n1-64k-64

----------------------------------------------------------------------------
dellboy
Samsung SSD 970 EVO 500GB__1 /dev/nvme0n1
model name : Intel(R) Core(TM) i5-4570 CPU @ 3.20GHz
cpu cores : 4
5.4.0-120-generic #136-Ubuntu SMP Fri Jun 10 13:40:48 UTC 2022
----------------------------------------------------------------------------
bs   filesize iops      lat_ns    usr  sys
"64k" "8m"     21768    2931170   10   20
"64k" "16m"    19820    3219596   10   19
"64k" "32m"    18560    3438232   11   18
"64k" "64m"    17788    3587537   10   19
"64k" "128m"   17228    3704233    9   19
"64k" "256m"   16984    3757656   10   18
"64k" "512m"   16730    3815166    9   19
"64k" "1024m"  16635    3836762    9   19
"64k" "2048m"  16543    3857273   10   19
"64k" "4096m"  16430    3883922   10   19
"64k" "8192m"  16440    3882186    9   19
"64k" "16384m" 16350    3903643   10   18
"64k" "32768m" 16288    3918479    9   19
"64k" "65536m" 16315    3911921   10   18


  22000 +------------------------------------------------------------------+
        |         +        +         +        +         +        +         |
        |*               Samsung SSD 970 EVO 500GB__1 /dev/nvme0n1 ***A*** |
  21000 |-*                                                              +-|
        |  *                                                               |
        |  *                                                               |
        |   *                                                              |
  20000 |-+  A*                                                          +-|
        |      **                                                          |
        |        *                                                         |
  19000 |-+                                                              +-|
        |         A*                                                       |
        |           **                                                     |
  18000 |-+                                                              +-|
        |             A***                                                 |
        |                 *                                                |
        |                  A****                                           |
  17000 |-+                     A****                                    +-|
        |                            A****A***A****                        |
        |         +        +         +        +    A****A****A***A****A    |
  16000 +------------------------------------------------------------------+
        0         2        4         6        8         10       12        14
```
#### cache-finder-example-plot
```
./plot-cache-finder.sh /tmp/dellboy-wss-nvme0n1-64k-64
```
![wss.png](https://github.com/garyjlittle/fio-scripts/blob/44eef08781dd17e46c1da559f38d9141020dcb5e/wss.png)
