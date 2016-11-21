# A utilizar únicamente en Windows.

use 5.022_002;
use strict;
use warnings;
use utf8;

use English qw(-no_match_vars);
use Cwd 'abs_path';
use File::Basename;
use Servicio qw(instalar desinstalar);

# Si se ha pedido instalar o desinstalar
if ( defined $ARGV[0] and $ARGV[0] eq 'instalar' ) {
    # Para configurar el servicio necesitamos la ruta absoluta.
    my ( $nombre, $ruta ) = fileparse( abs_path($PROGRAM_NAME) );
    instalar($ruta);
}
elsif ( defined $ARGV[0] and $ARGV[0] eq 'desinstalar' ) {
    desinstalar();
}else{
	die "<instalar | desinstalar>\n";
}

exit 0;