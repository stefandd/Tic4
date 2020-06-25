# Tic4
A simple 4x4 Tic Tac Toe playing AI in Lua and Lobster. In addition to four in a row (or column or diagonal), four in a square also win. Other than playing with [Lobster](http://aardappel.github.io/lobster/README_FIRST.html) as a language that was new to me but which I quite liked, I also wanted to benchmark both languages using constructs that are as equivalent as possible. The <em>negamax</em> modules contain a generic negamax implementation and the <em>tic4</em> files implement the specific rules for this 4x4 TTT variant.

Examples of winning conditions:
<p>
o&ensp;.&ensp;.&ensp;.&emsp;&emsp; .&ensp;.&ensp;.&ensp;.<br>
.&ensp;o&ensp;.&ensp;.&emsp;&emsp; .&ensp;o&ensp;o&ensp;.<br>
.&ensp;.&ensp;o&ensp;.&emsp;&emsp; .&ensp;o&ensp;o&ensp;.<br>
.&ensp;.&ensp;.&ensp;o&emsp;&emsp; .&ensp;.&ensp;.&ensp;.<br>
</p>

#### Playing against it
You can run it to play against the computer (both the tic4 and negamax files are needed in each language) but you have to live with a very simple command line interface for now.<br>
```
lua/luajit tic4.lua
lobster tic4.lobster
```

#### Benchmark mode
One can also run it to *benchmark* the languages and implementations by calling<br>
```
lua/luajit tic4.lua bench
lobster tic4.lobster -- bench
```
This will compute the best move from an empty board to a search depth of 7 starting (a bit more than 1M positions) and report the time this took.

#### Benchmark results
<p>
Below are the results for my machine (i5-4690K @3.5GHz) using the latest Lobster (x64 Release using VS2019), Lua 5.1.4, and the HEAD version of Luajit 2.1-beta3. While the Lobster VM is currently already quite a bit faster than Lua 5.1.4, the version compiled to C++ (using the --cpp switch) even beats Luajit 2.1 which I think is remarkable given the maturity of Luajit. A different C++ compiler might even increase the advantage...

![Benchmark results](bench_results.png)
</p>
