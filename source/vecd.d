/**
* This module implements types and functions to expand and simplify the use of
* the $(LINK2 http://dlang.org/simd.html, vector extensions) of D.
*
* $(LINK2 http://github.com/nucular/vecd, GitHub) &middot; $(LINK2 http://nucular.github.io/vecd/docs/vecd.html, Online documentation)
* Copyright: Copyright the respective autors, 2015-
* License: $(LINK2 http://opensource.org/licenses/MIT, MIT License)
* Authors: nucular and $(LINK2 https://github.com/nucular/vecd/contributors, contributors)
*/

module vecd;
public import core.simd;

import std.traits;
import std.stdio;

/**
* Provides a generic template for vector-like data types.
*
* Makes use of SIMD types if available and falls back to a static-sized array
* if not.
*
* Params:
*   T = The simple type of the elements of the vector
*   D = The number of dimensions/length of the vector
*
* Macros:
*   GVEC = A vector of `$1`s.
*/
struct gvec(T, uint D)
{
  mixin(
    "static if (__traits(compiles, "~T.stringof~D.stringof~"))\n"
    ~ "  " ~ T.stringof ~ D.stringof ~ " data;\n"
    ~ "else\n"
    ~ "  " ~ T.stringof ~ "[" ~ D.stringof ~ "] data;"
  );

  gvec!(T, D) opUnary(string op)()
  {
    mixin(
      "static if (__traits(compiles, " ~ op ~ "data))\n"
      ~ "  return " ~ op ~ "data\n"
      ~ "else\n"
      ~ "  return " ~ op ~ "data[];"
    );
  }

  gvec!(T, D) opBinary(string op)(gvec!(T, D) that)
  {
    mixin(
      "static if (__traits(compiles, data " ~ op ~ " that.data))\n"
      ~ "{\n"
      ~ "  return data " ~ op ~ " that.data;\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  T[D] tmp = data[] " ~ op ~ " that.data[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
    );
  }

}

/**
* A vector of `bool`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias bvec(uint D) = gvec!(bool, D);
/**
* A vector of `int`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias ivec(uint D) = gvec!(int, D);
/**
* A vector of `uint`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias uvec(uint D) = gvec!(uint, D);
/**
* A vector of `float`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias vec(uint D) = gvec!(float, D);
/**
* A vector of `double`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias dvec(uint D) = gvec!(double, D);
