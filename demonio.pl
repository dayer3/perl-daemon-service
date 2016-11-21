#!/usr/bin/perl

# A utilizar únicamente en Linux.

use 5.022_002;
use strict;
use warnings;
use utf8;
use Carp;
use English qw(-no_match_vars);

use Cwd 'abs_path';
use File::Basename;

my $NOMBRE      = 'experimento';
my $NOMBRE_REAL = 'no-correr-directamente.pl';
my $RECURSO     = 'experimento.service';

# Para configurar el demonio necesitamos la ruta absoluta.
my ( $nombre, $ruta ) = fileparse( abs_path($PROGRAM_NAME) );

my $contenido = <<"CHORIZO";
[Unit]
Description=experimento

[Service]
Type=simple
ExecStart=$EXECUTABLE_NAME $ruta$NOMBRE_REAL

[Install]
WantedBy=multi-user.target
CHORIZO

open my $fh, '>', $RECURSO
    or confess "ERROR creando el recurso para Systemd: $ERRNO";
print {$fh} $contenido
    or confess "ERROR escribiendo el recurso para Systemd: $ERRNO";
close $fh or confess "ERROR cerrando el recurso para Systemd: $ERRNO";

say
    "\nCopiar $RECURSO a donde los almacena el sistema (p. ej. '/usr/lib/systemd/system')";
say "\tsudo cp $RECURSO /usr/lib/systemd/system/";
say 'Recargar Systemd';
say "\tsudo systemctl daemon-reload";
say 'Comprobar el estado';
say "\tsystemctl status $NOMBRE\n";

exit 0;
