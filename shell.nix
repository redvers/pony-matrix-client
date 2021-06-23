with import <nixpkgs> {} ;
pkgs.mkShell {
  buildInputs = with pkgs; [
    ponyc
    stdenv
    openssl
  ];
}
