package PDF::Reuse::Barcode;

use 5.006;
use PDF::Reuse;
use strict;
use warnings;

our $VERSION = '0.06_02';

my ($str, $xsize, $ysize, $height, $sPtn, @sizes, $length, $value, %default);

sub init
{  %default   = ( value           => '0000000',
                  x               => 0,
                  y               => 0,
                  size            => 1,
                  xsize           => 1,
                  ysize           => 1,
                  rotate          => 0,
                  background      => '1 1 1',
                  drawbackground  => 1,
                  text            => 'yes',
                  prolong         => 0,
                  hide_asterisk   => 0,
                  mode            => 'Type3');
   $str    = '';
   $xsize  = 1;
   $ysize  = 1;
   $height = 37;
   $sPtn   = '';
   @sizes  = ();
   $length = 0;
   $value  = ''
}


sub general1
{  $default{'xsize'} = 1 unless ($default{'xsize'} != 0);
   $default{'ysize'} = 1 unless ($default{'ysize'} != 0);
   $default{'size'}  = 1 unless ($default{'size'}  != 0);
   $xsize = $default{'xsize'} * $default{'size'};
   $ysize = $default{'ysize'} * $default{'size'};
   $str  = "q\n";
   $str .= "$xsize 0 0 $ysize $default{'x'} $default{'y'} cm\n";
   if ($default{'rotate'} != 0)
   {   my $radian = sprintf("%.6f", $default{'rotate'} / 57.2957795);    # approx.
       my $Cos    = sprintf("%.6f", cos($radian));
       my $Sin    = sprintf("%.6f", sin($radian));
       my $negSin = $Sin * -1;
       $str .= "$Cos $Sin $negSin $Cos 0 0 cm\n";
   }
}

sub general2
{  $length     = 20 + (length($sPtn) * 0.9);
   my $height  = 38;
   my $step    = 9;
   my $prolong = 0;
   if ($default{'prolong'} > 1)
   {  $prolong  = $default{'prolong'};
      $height  = 26 + ($prolong * 12);
   }
   if ($default{'drawbackground'})
   {   $str .= "$default{'background'} rg\n";
       $str .= "0 0 $length $height re\n";
       $str .= 'f*' . "\n";
       $str .= "0 0 0 rg\n";
   }

   prAdd($str);

   @sizes = prFontSize(12);

   if ($default{'mode'} eq 'Type3')
   {  prBar( 10, $step, $sPtn);
   }
   else  # graphic mode
   {  $str = Bar( 10, $step, $sPtn);
   }

   $prolong--;

   if ($prolong > 0)
   {   $sPtn =~ s/G/1/go;
       while ($prolong > 0)
       {  if ($prolong > 1)
          {   $prolong--;
              $step += 12;
          }
          else
          {   $step += (12 * $prolong);
              $prolong = 0;
          }
          if ($default{'mode'} eq 'Type3')
          {  prBar( 10, $step, $sPtn);
          }
          else   # graphic mode
          {  $str .= Bar( 10, $step, $sPtn);
          }
       }
    }
    # print the graphic mode bars
    if ($default{'mode'} ne 'Type3')
    {   $str .= "B\n";
        prAdd($str);
    }

}

sub general3
{  $str = "Q\n";
   prAdd($str);
   prFontSize($sizes[1]);
}

sub standardEnd
{  general2();

   if ($default{'text'})
   {   my @vec = prFont('C');
       prFontSize(10);
       my $textLength = length($value) * 6;
       my $start = ($length - $textLength) / 2;
       prText($start, 1.5, $value);
       prFont($vec[3]);
    }
   general3();

   1;
}

sub Bar
{  my ($x, $y, $pattern) = @_;
   my $yEnd = $y + 20;
   my $yG   = $y - 3;

   my $string = "0.92 w\n 0 0 0 RG\n";
   for (split(//, $pattern))
   {   if ($_ eq '1')
       {  $string .= "$x $yEnd m\n $x $y l\n";
       }
       elsif($_ eq 'G')
       {  $string .= "$x $yEnd m\n $x $yG l\n";
       }
       $x += 0.91;
   }
   return $string;
}

sub Code128
{  eval 'require Barcode::Code128';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = Barcode::Code128->new();
   if (! $oGDBar)
   {  die "The translation of $value to barcodes didn't succeed, aborts\n";
   }
   else
   {
      $sPtn = $oGDBar->barcode($value);
      $sPtn =~ tr/#/1/;
      $sPtn =~ tr/ /0/;
   }
   standardEnd();
   1;
}


sub Code39
{  eval 'require GD::Barcode::Code39';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::Code39->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::Code39::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }
   if ($default{hide_asterisk})
   {  $value =~ s/^\*//;
      $value =~ s/\*$//;
   }
   standardEnd();
   1;
}

sub COOP2of5
{  eval 'require GD::Barcode::COOP2of5';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::COOP2of5->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::COOP2of5::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }

   standardEnd();
   1;
}

sub IATA2of5
{  eval 'require GD::Barcode::IATA2of5';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::IATA2of5->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::IATA2of5::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }

   standardEnd();
   1;

}

sub Industrial2of5
{  eval 'require GD::Barcode::Industrial2of5';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::Industrial2of5->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::Industrial2of5::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }

   standardEnd();
   1;
}

sub Matrix2of5
{  eval 'require GD::Barcode::Matrix2of5';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::Matrix2of5->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::Matrix2of5::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }

   standardEnd();
   1;
}

sub NW7
{  eval 'require GD::Barcode::NW7';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::NW7->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::NW7::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }

   standardEnd();
   1;
}



sub EAN13
{  eval 'require GD::Barcode::EAN13';
   init();
   my %param = @_;
   for (keys %param)
   {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
    $value = $default{'value'};

    general1();

    if ($value =~ m'([^0-9]+)'o)
    {  die "Invalid character $1, aborts\n";
    }

    if (length($value) == 12)
    {  $value .= GD::Barcode::EAN13::calcEAN13CD($value);
    }
    my $oGDBar = GD::Barcode::EAN13->new($value);
    if (! $oGDBar)
    {  die "$GD::Barcode::EAN13::errStr\n";
    }
    else
    {  $sPtn = $oGDBar->barcode();
    }
    general2();

    if ($default{'text'})
    {   my $siffra = substr($value, 0, 1);
        my $del1   = substr($value, 1, 6);
        my $del2   = substr($value, 7, 6);

        my @vec = prFont('C');

        prFontSize(10);

        prText(1, 2, $siffra);
        prText(14, 2, $del1);
        prText(56, 2, $del2);

        prFont($vec[3]);
     }
     general3;
     1;
}

sub EAN8
{  eval 'require GD::Barcode::EAN8';
   init();
   my %param = @_;
   for (keys %param)
   {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
    $value = $default{'value'};

    general1();

    if ($value =~ m'([^0-9]+)'o)
    {  die "Invalid character $1, aborts\n";
    }

    if (length($value) == 7)
    {  $value .= GD::Barcode::EAN8::calcEAN8CD($value);
    }
    my $oGDBar = GD::Barcode::EAN8->new($value);
    if (! $oGDBar)
    {  die "$GD::Barcode::EAN8::errStr\n";
    }
    else
    {  $sPtn = $oGDBar->barcode();
    }
    general2();

    if ($default{'text'})
    {   my $del1   = substr($value, 0, 4);
        my $del2   = substr($value, 4, 4);
        my @vec = prFont('C');
        prFontSize(10);
        prText(14, 2, $del1);
        prText(42.5, 2, $del2);
        prFont($vec[3]);
    }
    general3;
    1;
}

sub ITF
{  eval 'require GD::Barcode::ITF';
   init();
   my %param = @_;
   for (keys %param)
    {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
     $value = $default{'value'};

   general1();

   my $oGDBar = GD::Barcode::ITF->new($value);
   if (! $oGDBar)
   {  die "$GD::Barcode::ITF::errStr\n";
   }
   else
   {  $sPtn = $oGDBar->barcode();
   }

   standardEnd();
   1;
}

sub UPCA
{  eval 'require GD::Barcode::UPCA';
   init();
   my %param = @_;
   for (keys %param)
   {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
    $value = $default{'value'};

    general1();

    if ($value =~ m'([^0-9]+)'o)
    {  die "Invalid character $1, aborts\n";
    }

    if (length($value) == 11)
    {  $value .= GD::Barcode::UPCA::calcUPCACD($value);
    }
    my $oGDBar = GD::Barcode::UPCA->new($value);
    if (! $oGDBar)
    {  die "$GD::Barcode::UPCA::errStr\n";
    }
    else
    {  $sPtn = $oGDBar->barcode();
    }
    general2();

  if ($default{'text'})
   {   my $siffra1 = substr($value, 0, 1);
       my $del1    = substr($value, 1, 5);
       my $del2    = substr($value, 6, 5);
       my $siffra2 = substr($value, 11, 1);

       my @vec = prFont('C');

       prFontSize(10);

       prText(2, 2, $siffra1);
       prText(20, 2, $del1);
       prText(56, 2, $del2);
       prText(97, 2, $siffra2);

       prFont($vec[3]);
    }
    general3;
    1;
}

sub UPCE
{  eval 'require GD::Barcode::UPCE';
   init();
   my %param = @_;
   for (keys %param)
   {   my $lc = lc($_);
        if (exists $default{$lc})
        {  $default{$lc} = $param{$_};
        }
        else
        {  print STDERR "Unknown parameter $_ , not used \n";
        }
    }
    $value = $default{'value'};

    general1();

    if ($value =~ m'([^0-9]+)'o)
    {  die "Invalid character $1, aborts\n";
    }

    if (length($value) == 6)
   {  $value  = '0' . $value;
      my $cd  = GD::Barcode::UPCE::calcUPCECD($value);
      $value .= $cd;
   }
   elsif (length($value) == 7)
   {  my $cd  = GD::Barcode::UPCE::calcUPCECD($value);
      $value .= $cd;
   }
    my $oGDBar = GD::Barcode::UPCE->new($value);
    if (! $oGDBar)
    {  die "$GD::Barcode::UPCE::errStr\n";
    }
    else
    {  $sPtn = $oGDBar->barcode();
    }
    general2();

  if ($default{'text'})
   {   my $siffra = substr($value, 0, 1);
       my $del1   = substr($value, 1, 6);
       my $del2   = substr($value, 7, 1);

       my @vec = prFont('C');

       prFontSize(10);

       prText(2, 2, $siffra);
       prText(14, 2, $del1);
       prText(58, 2, $del2);

       prFont($vec[3]);
    }
    general3;
    1;
}


1;


__END__


=head1 NAME

PDF::Reuse::Barcode - Create barcodes for PDF documents with PDF::Reuse

=head1 SYNOPSIS

   use PDF::Reuse;
   use PDF::Reuse::Barcode;
   use strict;

   prFile('bars.pdf');

   PDF::Reuse::Barcode::ITF (x       => 70,
                             y       => 530,
                             value   => '0123456789',
                             prolong => 2.96);

   prEnd();

=head1 DESCRIPTION

This is a sub-module to PDF::Reuse. It creates barcode "images" to be used in
PDF documents. It uses GD::Barcode and its sub-modules: GD::Barcode::Code39,
COOP2of5, EAN13 and so on, to calculate the barcode pattern. For Code128 it uses
Barcode::Code128.

Normally the barcodes are displayed on a white background and with the characters
under the bars. You can rotate the "image", make it smaller or bigger, prolong the
bars and change the background.
(But then, don't forget to test that your barcode scanner still understands it.)

If you don't change the size of the "image", the bars are approximately 24 pixels
high (the guard bars a few pixels longer) and the box/background is 38 pixels high
and something like 20 pixels wider than the barcodes. The text under the bars are
10 pixels high.

The barcodes are generated using a Type3 font by default. Ghostscript and xpdf
don'thave support for Type3 fonts. If you want to target engines that don't
handle Type3 fonts properly, see the "mode" parameter.

=head1 FUNCTIONS

All functions are called in a similar way. Just replace 'ITF' in the example
under SYNOPSIS with some other function name and let the value parameter follow
the rules of that function.

=head2 Code128

Creates Code128 barcodes with the help of Barcode::Code128. Look at that module
for further information.

  # code128.pl

  use PDF::Reuse;
  use PDF::Reuse::Barcode;
  prFile('code128.pdf');
  PDF::Reuse::Barcode::Code128(x     => 100,
                               y     => 730,
                               value => '00000123455555555558');
  prEnd();


The constants CodeA, FNC1, SHIFT and so on, are not imported, but if you really
need them (??), try to use the character values instead.

  CodeA      0xf4        CodeB      0xf5         CodeC      0xf6
  FNC1       0xf7        FNC2       0xf8         FNC3       0xf9
  FNC4       0xfa        Shift      0xfb         StartA     0xfc
  StartB     0xfd        StartC     0xfe         Stop       0xff

  # unusual.pl

  # Instead of FCN1

  use PDF::Reuse;
  use PDF::Reuse::Barcode;
  prFile('unusual.pdf');
  PDF::Reuse::Barcode::Code128(x     => 100,
                               y     => 430,
                               value => chr(0xf7) . '00000123455555555558',
                               text  => 0 );

   # Font and font size has to be chosen
   # Text could be put manually at x => 110
   #                               y => 431
   # The size, xSize, ySize and rotation doesn't influence the text
   # in this case ...

  prEnd();


=head2 Code39

Translates the characters 0-9, A-Z, '-', '*', '+', '$', '%', '/', '.' and ' '
to a barcode pattern.

In Code39, the asterisk is used as the start and stop bar, but PDF::Reuse::Barcode
expects you to supply the asterisks. If you do not want them to display in the
text version, pass the option "hide_asterisk" as in

    PDF::Reuse::Barcode::Code39 (x             => 10,
                                 y             => 20,
                                 value         => '*62002*',
                                 hide_asterisk => 1);

=head2 COOP2of5

Creates COOP2of5 barcodes from a string consisting of the numeric characters 0-9

=head2 EAN13

Creates EAN13 barcodes from a string of 12 or 13 digits.
The check number (the 13:th digit) is calculated if not supplied.
If there is given check number it is not controlled.

=head2 EAN8

Translates a string of 7 or 8 digits to EAN8 barcodes.
The check number (the 8:th digit) is calculated if not supplied. If there is
given check number it is not controlled.

=head2 IATA2of5

Creates IATA2of5 barcodes from a string consisting of the numeric characters 0-9

=head2 Industrial2of5

Creates Industrial2of5 barcodes from a string consisting of the numeric characters 0-9

=head2 ITF

Translates the characters 0-9 to a barcodes. These barcodes
could also be called 'Interleaved2of5'.

=head2 Matrix2of5

Creates Matrix2of5 barcodes from a string consisting of the numeric characters 0-9

=head2 NW7

Creates a NW7 barcodes from a string consisting of the numeric characters 0-9

=head2 UPCA

Translates a string of 11 or 12 digits to UPCA barcodes. The check number (the 12:th
digit) is calculated if not supplied. If there is given check number it is not
controlled.

=head2 UPCE

Translates a string of 6, 7 or 8 digits to UPCE barcodes. If the string is 6 digits
long, '0' is added first in the string. The check number (the 8:th digit) is
calculated if not supplied. If there is given check number it is not controlled.

=head1 COMMON PARAMETERS

All functions accepts these parameters.
The parameters should be put in a hash.
All of them are optional, except 'value'.

=head2 value

A string of characters which will be translated to barcodes.

=head2 x

Number of pixels along the x-axis where to put the lower left "corner" of the
barcode image.

=head2 y

Number of pixels along the y-axis where to put the lower left "corner" of the
barcode image.

=head2 size

A (decimal) number. If you define a number for this parameter, all sizes along
the x- and y-axes will multiplied by this number. Also the text under the bars
will be scaled.

=head2 xSize

A (decimal) number. If you define a number for this parameter, all sizes along
the x-axis will multiplied by this number. The text under the bars are also
affected.

=head2 ySize

A (decimal) number. If you define a number for this parameter, all sizes along
the y-axis will multiplied by this number. The text under the bars are also
affected.

=head2 prolong

0 or a decimal number greater than 1. Prolongs the bars with this factor.
In reality tells the module to prolong the bars by repeatedly rewriting the barcode
pattern.

=head2 text

Normally this parameter is 'yes', which will cause the digits to be written as
text under the barcodes. If this parameter is '' or 0, the text will be suppressed.

=head2 drawBackground

By default this parameter is 1, which will cause the barcodes to be drawn on
a prepared background. If this parameter is '' or 0, the current background
will be used, and the module will not try change it.

=head2 background

Normally it is '1 1 1', which will draw a white background/box around the barcodes.
Choose another RGB-combination if you want another color.

=head2 rotate

A degree to rotate the barcode image counter-clockwise

=head2 mode

Defaults to 'Type3', which means that a Type3 font will be embedded in the PDF
document and then used to print the barcodes. Type3 fonts are not supported by
some PDF interpreters, namely Ghostscript and xpdf.

Set the mode to 'graphic' (currently, any string that doesn't match 'Type3' will
do, but you should not count on this) to get graphic bars that work on all
engines.

=head1 EXAMPLE

  use PDF::Reuse;
  use PDF::Reuse::Barcode;
  use strict;

  prFile('bars.pdf');

  #################################################################
  # First a rectangle is drawn in the upper part of the page
  #################################################################

  my $str = "q\n";                    # save the graphic state
  $str   .= "0.9 0.5 0.5 rg\n";       # a fill color
  $str   .= "10 400 440 410 re\n";    # a rectangle
  $str   .= "b\n";                    # fill (and a little more)
  $str   .= "Q\n";                    # restore the graphic state

  prAdd($str);

  #################################
  # An image with prolonged bars,
  #################################

  PDF::Reuse::Barcode::ITF (x       => 50,
                            y       => 700,
                            value   => '0123456789',
                            prolong => 2.96);

  #############################
  # A magnified barcode image
  #############################
  PDF::Reuse::Barcode::EAN13 (x       => 250,
                              y       => 700,
                              value   => '012345678901',
                              size    => 1.5);

  ####################################################################
  # "Graphic" barcodes. (The others on this page use a special font)
  ####################################################################

  PDF::Reuse::Barcode::EAN13 (x       => 250,
                              y       => 600,
                              value   => '012345678901',
                              size    => 1.5,
                              mode    => 'graphic');

  ######################################################
  # A barcode image magnified a little along the y-axis
  ######################################################

  PDF::Reuse::Barcode::EAN8 (x       => 150,
                             y       => 500,
                             value   => '0123456',
                             ySize   => 1.2);

  ################################
  # With the box in a light color
  ################################

  PDF::Reuse::Barcode::Code39 (x             => 70,
                               y             => 300,
                               value         => '*THIS IS SOMETHING*',
                               background    => '0.99 0.97 0.97',
                               hide_asterisk => 1);

  #############################################
  # With everything expanded along the x-axis
  #############################################

  PDF::Reuse::Barcode::NW7 (x     => 70,
                            y     => 100,
                            value => '012345678901',
                            xSize => 2);

  #################################################
  # An image, 90 degrees rotated, might look
  # strange on the screen, should be ok as printed
  #################################################

  PDF::Reuse::Barcode::UPCA (x              => 400,
                             y              => 100,
                             value          => '12345678901',
                             drawBackground => 0,
                             rotate         => 90);

  prEnd();



=head1 LIMITATION

EAN13, EAN8, UPCA and UPCE have "guard" bars. These, a little longer bars, are often
a little blurred at the lower ends when they are displayed on a screen. If you
magnify the image, the lines are displayed correctly. When you print the image
there shouldn't be any problem, if you use at least 600 dpi.

Also rotated barcodes might look strange on a screen. Most often they are much
better as printed on paper. Try to use "size" rather than "prolong", when you have
a rotated barcode "image". (If it has been rotated 90 or 270 degrees, you can make
the bars longer with the help of xSize.)

=head1 SEE ALSO

These modules are used for calculation of the barcode pattern

   Barcode::Code128
   GD::Barcode
   GD::Barcode::Code39
   GD::Barcode::COOP2of5
   GD::Barcode::EAN13
   GD::Barcode::EAN8
   GD::Barcode::IATA2of5
   GD::Barcode::Industrial2of5
   GD::Barcode::ITF
   GD::Barcode::Matrix2of5
   GD::Barcode::NW7
   GD::Barcode::UPCA
   GD::Barcode::UPCE

=head1 AUTHOR

Lars Lundberg, elkelund@worldonline.se

=head1 THANKS TO

Everyone who has helped me with corrections and ideas, Martin Langhoff among others.
And of course credits to Kawai Takanori and William R. Ward who have written the
modules for calculating the barcode patterns.

=head1 COPYRIGHT

Copyright (C) 2003 - 2004 Lars Lundberg, Solidez HB. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER

You get this module free as it is, but nothing is guaranteed to work, whatever
implicitly or explicitly stated in this document, and everything you do,
you do at your own risk - I will not take responsibility
for any damage, loss of money and/or health that may arise from the use of this module!
