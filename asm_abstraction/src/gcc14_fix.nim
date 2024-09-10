# included

# silence errors...
{.
  emit:
    """
#if defined __GNUC__ && __GNUC__ >= 14
#pragma GCC diagnostic warning "-Wincompatible-pointer-types"
#endif
"""
.}
