{ coq, mkCoqDerivation, mathcomp, mathcomp-finmap, mathcomp-bigenough,
  lib, version ? null }:
with lib; mkCoqDerivation {

  namePrefix = [ "coq" "mathcomp" ];
  pname = "multinomials";
  owner = "math-comp";
  inherit version;
  defaultVersion =  with versions; switch [ coq.version mathcomp.version ] [
      { cases = [ (range "8.7" "8.13")  "1.11.0" ];             out = "1.5.2"; }
      { cases = [ (range "8.7" "8.11")  (range "1.8" "1.10") ]; out = "1.5.0"; }
      { cases = [ (range "8.7" "8.10")  (range "1.8" "1.10") ]; out = "1.4"; }
      { cases = [ "8.6"                 (range "1.6" "1.7") ];  out = "1.1"; }
    ] null;
  release = {
    "1.5.2".sha256 = "15aspf3jfykp1xgsxf8knqkxv8aav2p39c2fyirw7pwsfbsv2c4s";
    "1.5.1".sha256 = "13nlfm2wqripaq671gakz5mn4r0xwm0646araxv0nh455p9ndjs3";
    "1.5.0".sha256 = "064rvc0x5g7y1a0nip6ic91vzmq52alf6in2bc2dmss6dmzv90hw";
    "1.5.0".rev    = "1.5";
    "1.4".sha256   = "0vnkirs8iqsv8s59yx1fvg1nkwnzydl42z3scya1xp1b48qkgn0p";
    "1.3".sha256   = "0l3vi5n094nx3qmy66hsv867fnqm196r8v605kpk24gl0aa57wh4";
    "1.2".sha256   = "1mh1w339dslgv4f810xr1b8v2w7rpx6fgk9pz96q0fyq49fw2xcq";
    "1.1".sha256   = "1q8alsm89wkc0lhcvxlyn0pd8rbl2nnxg81zyrabpz610qqjqc3s";
    "1.0".sha256   = "1qmbxp1h81cy3imh627pznmng0kvv37k4hrwi2faa101s6bcx55m";
  };

  propagatedBuildInputs =
    [ mathcomp.ssreflect mathcomp.algebra mathcomp-finmap mathcomp-bigenough ];

  meta = {
    description = "A Coq/SSReflect Library for Monoidal Rings and Multinomials";
    license = licenses.cecill-c;
  };
}