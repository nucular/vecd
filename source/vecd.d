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

/**
* Thrown when a vector operation is not supported on the target platform.
*/
class NotSupportedError : Error
{
  @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
  {
    super(msg, file, line, next);
  }

  @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
  {
    super(msg, file, line, next);
  }
}

/**
* Provides a generic template for vector-like data types.
*
* Makes use of SIMD types if available and falls back to a static-sized array
* if not.
*
* Params:
*   T = The simple type of the elements of the vector
*   D = The number of dimensions/length of the vector
*/
struct gvec(T, uint D)
{
  mixin(
    "static if (is("~T.stringof~D.stringof~"))\n"
    ~ "  " ~ T.stringof ~ D.stringof ~ " data;\n"
    ~ "else\n"
    ~ "  " ~ T.stringof ~ "[" ~ D.stringof ~ "] data;"
  );

  /**
  * Implements all unary operators on a vector.
  *
  * Params:
  *   op = The operator
  */
  gvec!(T, D) opUnary(string op)()
  {
    mixin(
      "static if (__traits(compiles, " ~ op ~ "data))\n"
      ~ "{\n"
      ~ "  return " ~ op ~ "data;\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, " ~ op ~ "data[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = " ~ op ~ "data[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else static if (hasMember!(typeof(data), \"array\"))\n"
      ~ "{\n"
      ~ "  T[D] tmp = " ~ op ~ "data.array[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Unary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
  }
  ///
  unittest
  {
    vec!3 a = {[-1f, 0f, 1f]};
    assert(-a == vec!3([1f, -0f, -1f]));
  }

  /**
  * Implements all binary operators on two vectors of the same length and type.
  *
  * Params:
  *   op = The operator
  *   that = The second vector
  */
  gvec!(T, D) opBinary(string op)(gvec!(T, D) that)
  {
    mixin(
      "static if (__traits(compiles, data " ~ op ~ " that.data))\n"
      ~ "{\n"
      ~ "  return  gvec!(T, D)(data " ~ op ~ " that.data);\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data[] " ~ op ~ " that.data[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data[] " ~ op ~ " that.data[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else static if (hasMember!(typeof(data), \"array\"))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data.array[] " ~ op ~ " that.data.array[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Binary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
  }
  ///
  unittest
  {
    vec!2 a = {[1, 2]};
    vec!2 b = {[3, 4]};
    assert(a + b == vec!2([4, 6]));
    assert(a - b == vec!2([-2, -2]));
    assert(a * b == vec!2([3, 8]));
    assert(b / a == vec!2([3, 2]));
  }

  /*
  * Implements a conversion from vector to string.
  */
  string toString()
  {
    import std.conv;
    return to!string(data);
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
