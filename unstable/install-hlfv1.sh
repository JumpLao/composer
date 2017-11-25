ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.15.3
docker tag hyperledger/composer-playground:0.15.3 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �WZ �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T�b����#��E9�������� x�X��������B��,[3�M�&�1����� {�a �Ǆ����_�5Y��F��\���a�5�d�Hm +2�)��1-��Hk��I��1rz�բ�*�CWw<Dt� ˀ��ظ�}\�S��uX�4%��n�t>�{�At<���C��ŉ��|�t�L��\��������=#K��vs^��������B��D<8>.
�r�_<�!RӌH�M�6]KA�]}
�~��E�Z��")�wޗ���T����X�㏠�S��{݄*��`Y��_L����;?��s�R�K���a��+�:@Ȓնf��50�$pg��K�\�K���a��w����|��6�{�A��k�x���Lĥ�/. X���&`�v����D�sᄗ�"[������ ��,P�i6pL@Z�;�M!����ˇ9P7-�9!�촑�`��v@ǵȞ�Ϸci]�a��"�d!��9��ǩt?�u0"ACsh9��Z:Ii:N�ތDpNӭ����G嘦n�Iy\��2���4-Z�@R~	O>]S�aS�2֚&
	a��j�~ϴT��D
0HY�M��4�fRlSwI��D�w�������5W������E6���w@(D>Ꚏ@�����xT)��i�A��EC��P�S4��iHj�q�yY|X�k7�����$&rep	�C�3�˕�3��d]O�Ӂy]����s'�?._�������<��u�P�$�&t@K�u X�mvND�rC3�C�����s�0���S�!бA��3F��7Ě<���`Y��!i�9)M����1۫|X ~^����urT�q�rR�L]�̅q�0�]��{�Tr��6l�6�A�N�^�V���=%��Aa��Ph�����o�ق{�nX#�d�zL*��|���
��0p�UfڪN��`}|��Ty�#�4�>m�@�����q�`��v��:��O.��]͡��쪉���&n(�9(G��A�Hq@��)M`R��,�}�����	~���:9��Y}������m>�7�`���;Q#,W)���$�gT�^ P�Ny�ŋ��!��4/���a<t�9~:��¨���K��
S�2��m����cR,�\���������/����E!6��<���YxvRz��Ygަݣ�b�k�2u�!��k���Z!�'l��V�I�J[1�0��\�}9U�T�~�S�q쯾aW���Ջ ����ʡsl�f�d)�z�)�s���g�#�ٷy��fװ���mt�mM���Y�F��x�-��F�����)O`mu<K���+r���g����C�&;/��6��ϮTa��/yu f������%�=_]#	X���7`u*�?�U�w���#��嵢n���!0�vY,x����Z��'eI�̨�d��!�͊~�lğ��m�;9,0
;>�دh���o��X&�S�g5�e�	�+�?$\l9�/ ����^5���~%�	�'��*���穠n�m��¼� �q�M?�_��>0L����ܧ8K��<7i�ţ�R����̓�5���6��!�B!<;Ե30X�1ᡀ�Ҿ�:�)�?a0������q,� ����8s��Y�����������9~�������<�f��e�����r�_L��f�n�	�l �2�uб4��D�mh�v�!.xu�j�r�E�Q�7�B�\J�l���e?����m��G�a�����?J���%��"9v�vP� #,=e�ËlT�U��?*܊��D
��8can�LD$��4uS�:	�r��j��U���AI��'���^������Tܪ���OF4�H1UƎ�1B�8x�̙�޹3�;�Fנ���f�=�`�X�\����?ϥ�Y�\����F���߅���?(�d�\���!"lxs)��S�*��7���A8)��G|!k�. !>̅�Y�
�����]
��m�(��*M�6V�������s)d��c]���DAZ������Ü�y��O�����o�{yf�`�!�C�p������%�0��YK?*#�F�N��١Ѐ���k�P6�.0����ϼ��?��\�l@�V�7�����\keӲ��:ܯN-��v71C}�6�!��������x'�A6Uۋ�|�F�c��Պ=��3$��Y@H%�fM�E��M7��IR�H�_�V�Zc�a�O��j ����hu�������Af?^����3u� �V	�G��x������c��\8
��p�� ou��H�Z�M�v6�ı�����i(�Ļ���,#��#�6�Fg������K�Y*Ƅ���v����Z�c��oP�a��:uC�(;��X��^ƊH�^����g.�;��~���A��Ѷ;�4��Ǎ�/�Gk#�upN��K�3��r�r%�~7s�uųG��ġ�k�i;L�9�a���f��6Y��J�˕L,XW�&���a�C�X��)�(�Q�H��"�6��(D�T�P!�DEN��F&j|�E)��n1�L���m�a]�)D2�ԦA�I/�@� `��Bb|��v���t�O)M�y՛�@�3]sA�� !��6�|x^�h��h �4+�m��7���!:5R>r��,�im�0���|_z����L����R��
����F*�\�����ok��:���ĉ�/A��K�o!���-f#�ږm��t�N����+&�'xuɘ��G�3�"���}\P���_�I������B`^���.�ᑟ��O�+f������?����eH�4�naq�tUF�L� fxm!"�ga���;��v�k�\�۵�5.٧���]��\1������2���n�r��02o���ʮ��Ow	��5��������`��w����>�Ǘ���;��h󦧰s6������I���?I�.���}˼g�}�������������X~�Ek�"�Bb���
/&`�V��D"V�%Q�C$�H���Z"**PLH�_�oHBmC�V��[�/�2��W�a�N�tt�s��f�;������U�I��mZ��W�����`��_߬��q"���wߌ�,�{��c�������f�����7��7Gv^-{�Vc��&qJ�D�p���O���d��=�����Z�w�q��?�-����G��p��6<f������xl9�/.|��(�N\M�iCO��L�<.��2�����z�bq.2p�Nn���d*�y����h����1ʼG7��6�v�!1��df;W �|"�ͥ�J���5�\j�4���TC��r#W��qXx�W#����:����^�ǹ]�$w~�e0nO9��a
rk[櫙d3�:<̟e��R�Q8Ĥ*�V�Y��۵�+eβ�r��S*�C��%��J;�����q�]�_{f%��蟜gܓ��f�u�>)K�5�;�I����W2B����kO���4�B���
�9!_�q���pD�Ni7H{k�&k���K�Ӈ��v���z���qÑڥ��ݢ����IWiK��J�(�,z5?��U!��2'��#��.���3�|��r�wT<*9�H�q[�������l��{�B�VI���L淓��弘���T������\NNn��g�"��:+W��^7^x���JN,���Ty��1�ZG�q�T��]y7ղ�I��I���Ko��WJ�1��n�vO+��^^q_`i�t/��􊤏wi9O�z��O����|*���Mj��z�V>�+�m���d.�xkX��Vo��������������J�������f�S2א�j*WL��n1��Hej�c$n��t��4����tNBe��;LtSj��k��ݘ�.��f��t`&��'�n����0�s 9���Z��䭷�Bz������H8�˞i4�4��@sL`��k��'^�1[��������g�e��Mx��P���޹;D���뾄���?:y���e��b `'��`7sLS3���^�����6׃Ć*����%wM-��Z��c�d_>���kT�>����M#弴[4��M��,��n�.V�N��:��T�����N���j<f��V�_,I})�#�z�#lk�T�Ȩ��[�� 9������N�Cm��7�|�13\��V�S�����abv��1C�yQ�|��DBB��� ��Ob�u��y�$f^'���Gb�u��y=$f^���?b�u��y�#f^爙�1׺F_xL�]����ī��������sk���Kx�y��4�o����@���&�r����m�2��߮K�š����J�ؐ30޳2�tV���gG7b��U���ǌ��=��[������a��h��lv��ݽֹc8mC>��{��;�;�Q������
:p��}�V���G��VL�o����z�[�.���xRf�oѸ�\2�Y�0�u�H�J��5�<!Q��ס=�7!�,��!k����0b�� Sc���}�a� Ҩ���5�$�wt-��䪤�
S���O��R�/qB�g� �C�@_�=� @�lC����Z�~߼	E��A
��2B��iEPC�٣!�d����/�z i�(����[�;�?����(&��2��<��m�:x��ȝ���`���dA�Q8M����d�k��� tF��4�Hp��tr��M���y�k�q �q ��
z�F=hЇ)���Vn>�uO=
>Zm�  h hY�O�D,�ci�ƴ3x��	o���ǨN�x��U_ߞLh OK胫a���4����Re�а����N�p���76���)�Ϩ,d��9~����a���4�^�R6U��K�I�CWwֽ���	o��؍�^\�����_�H��do$⿛�F��a��m�Pwq�#t�0��C��!)�P�*��\�;d�u��?��̶��_7M����N����)�����q�+�	��ƈ�ε��B�y0*�Ӆ�g�YbI����&g��;v1=̷�ۙi�?Ŷ��δ�.���r�J�s:�i�˙vږ5��#-҂悸������r .+b.���g���8�r}���f��MuUdċ��Eċ��qIevvI����n��xs��v������@H#��c%�Ѥ4��'"6|F�^��K B<)���g�Ĵ�!�i5�λ�C�Oޚ��GD�v]k��rM�����x�C$	��J~�s����WcU[�?h��?����If{�+ kr�3�s`�H�`�?|�A�UPv���!��A�F3g'0Ŝـ� �Ɓ&X�˖3���,݋d[�t}���7:ėem�]�� �(�9T`���C�W,�4�{��q��Že���� �Ӿ�5� �VG�|?����e��cP�G��#���b��|���5.)
�fǏ�4�TQ�1D<tkzC=B��Z�K6����kc ���(��m\��'RI|{��&����������g��y�~�_Z������'�_h���>���������_c?$�O���~�ދ�����{?AoE^�^א�IC��{�t2�T5	�RI5��hD
O�2��$rZ�J�2��Q)%GR�U	���R6G�I�Eʱ���������[�?���'���O�l��>�~��'��ñ����c��&������7c�s�������C��}���Ǿ&�����~��c?��7���DC\�7�5�6
��lY�����c�s%��O�.������'�z���'�
^c׽;�����qO`��@h�3������ vIn��.Hk_TW4)�t�I�Nz�[zy�0J�"�����zW��CQh
.����	��,&�Qn)�́��}+q.!�!���<�GՉBV�Bs�\T��[0`�ʢ2:Lu;�+۳.�s���uT�ŸE��ۢv��A56l�D�˰�����W�%3R+��D%as=�q����> VNu��ىi��Cj�F�Y���`U(T�-�ԝk�f;
R��
���n6�:�(%��^	t]����t��1���.*,z��.��W�ݩ7R�7��䘧��K���D�T:a�2��Tz����e�;���Զ�� �4��ӓ��>q���邃-rY�Z��vz��ORy[U���2��|��T�TZ�wZm�I�Yz>��bm���D9����v+q����?����J�J�zF%�ױ�[%���R��?^J(-���P�p�#�h易��V{��̏�g�����5.��Z\�0({>���`�P�^[�`P�\O�d�h ���[�p�t=���h�_�ӳ1�,fʳ�!+{=��t�L�#����9/�V�S"����6)�i�Í�N�R��tM5W?��5q-�O5җ�,�?�"~2=�����\
��\���WG5�6S��D��\Bɨ|�M���B��\��f\!�ֈQ��)�f3m�-��=g,��S��0��G�=g�jiHj\�vph�۽vm��1�R���G�lz�]@e��D�����/�{1�V�^���K�^x�*|��ka|����5�w�W������/7��S�e�2�~�{_����ୄ_.���$|H�}x���c�{�//�^��v�j�?|�e�~�V�߾�E.�b?��?���?���������̿���UV����Z��Nv^m��3�e��4��j_9#�%�y��K���'��^qca9��$�8v�Y �3�\�u��(��<��p9�g]��́��p�d�Q�*JG�EFW|a�3k�!0���I�i�̊(�2�t>]�c'u�p��r�z�3?Ps#�Z��-�#��3J�ΏdM�'E�Y�R���wVG�BY7�I��"�.v$�5��d��GbY����2z����,]���HCfZJy�*�7&�H2�����/���2G*Z��-�l�в��W��!(�j�f�6h�H[�GE�����E�(�Հ�㔜hأa�U0���\3'��`�Db���A���z�q�ß�S	��Vb��3��E���ߺ�h�PQ�CE��-'x�=j�J��Vj�>4Wg�����������l+ȅ}(��:�#R�:bE.)��e��[V��jZ ����0�=<�*�cץ���1���]�{@�+�9k�&±�rUN�NT�6:��3�%�^��ݢ-Ϊ�=�1��j%�7���D�
C6�1͊���樗#������q�ȟ�*�nuO�U��w�p�h�S�9OQ�4�x�r��.o�zg�(Ko�S�^(-�ٟ�e:����#��)��eጨn��?�iv�e�Z�w��K���V'\����1&��ݑt��Ң��謘�K��0_2x.C����u�Vn@�8��b�AY����t⿺�&�"$˵ ��Qc2>223��1u %�3Z�+��+H,�H��dQ�G���Pt�0��{l�_(L$��I��@��{��J�<N6ڇ�A~�g��V���ԁ�q�)Wć.o�����-^'�՞8!$�ε���8��6�m�pPL���ln`��`
%�u
H�%Ӯt����8�\I#���m��y�Ԡ�N4r��Sl(�����yC�����2��*Sy1#(��C�D��(�����2IJ#���a2F;!1nk��g�Hv&�p+��%ؔ�{=��k�X��]DL�^�\�ľt����ע�[X��ƫ�I�U�+W
u�_����hS����݊���*���4W�3[\N���W��m˴�"��c$G���{#��=���O�o?}�|{�=Gy���^�^"מ}>¾��;�C�4Tχ���tEoB�z%
��=���d��N�� FP��|�����h��H~���M����?�����šUu�ٶfǨ��m��)z��<:���Bf�����]�<��О�Y\���K���t���������t3��P��j?�]O�=��F��!���n��Sa�Z\CQ��� ��� ����TJ��i*�4���@4��4��L����?"{�|�&Di>�-z����~<��]g������?򿰞U��Q`#t�f�8�Ǐ֧=���5�f����gA^�bتo���D���N��h7,q�cj"_�==��7��-�$h�!��QKPϠ�7��?j=,�q�1�|�,�M��~��J
�h�3��kdLEoշ�9�Dz��Mǁ����G���������T�c�,8(h���3��3o��� d��|m��l�,��4b	�ƣ�{;H❸�?���F��s�h�Ez�c������'u�Ȩw���k�1�����Ά�>�\�B�#5"�p#&~��y6
EA�?Ycض"��E��H���X�����j?�J�
{���+'�!��B��>$�P�����It��nX�cŘH�~�i�'0\[/�N|)��k/$�f�.��+�0���CXW�wTh��)|v��a߉~�X�o=�ME.��"J�kH��Բm��_��`6��?`ТӷME��pi��oѺ�����oqd�dFKȡ!qhg�gA��F��1l�8uZRB��7'q���ת�g@����=D@�Q�ɧ�8ЏǶ�U����!N�?ɚj&�l]+\7#m<M)d��������g�Ah��A*�����8���K��=� 5=C���\�!��}8��C�3;���Z�E���-�����x�E�q���4�V���l�OW2� � 2 �"T�˰.�=ُ��&tx����3�L{��z��D#h�2
�^G06$���^ݨ��HZ��hW �D���P��l����IZ`��G[�e0�3 �a������U��]��N,׳���@�뵩!�`X꺋�=^�8�	в�p.�h��H��[��7	?<���� (|S����c�A���}�Ed�M���n{���v=!A��9�t�i��ZC(@�Q�;0tT&.{�#	�D��ebG Uk"��"r��}7nl9��I���&��c�G�������y�jtт��nAN�1M��P:���<|����8�:�Xs\k:��Ʀ��ܙ��ȱ�RDpގ8��������bG�z����g>�;���6.y�Oe����T2��;����ޏ�O��a��Jv�\�x%
�����pdó~g]��&�?���02ғ��(���|��Q��5�&��J;:��sQ-xyV�+Wh|�k=/X�p�gkG"IU�'��LJ�Ler�&QI-I��龢h}B��	I"�$�?G�r_���R*��$2-���h ؋<n#lya�P��h������xo��AN���WŎ	'̃9Ԗ���Ir��dY�SY<�J*Aj)�r�$�ө����鬖�d���`&�9-��)-i`b�d/��>�9q�T/���m#-2]��=��"%��:	����;�]X
��쬿��%�׸�֚,�X]�\��Wj�
w�U���<��/ƷD�J�l�k���H���-�m�-�K5�	:꿤�n�
N��y�v���tEh�y�I�x��0��.�����s�{�#;V��L8	݂�j	{�$t��d�Kg�j�h;n�}���P�,�ӵQ���0��x'�l��3Z�}@��/8L9�a���{��� ��j��q�-DG��%���k캤G,Ǵ��E�c���k|U|2��D"�Y'��41��}���OT6~0��ӣhـ�ΙMt���7��? UK����U|�ʉ�Z�@ �{��q���f���H�-r=�uZ,����X֋��EP�%����'K�4C��'yk�X���Z;_bL�_�)��*�S�l�h�%��0�?{��䓾d��9$Ll.�7��N�G�!�o����+H>t6�؍l�)k���.�c����O��M��j�/w���|���(�����/w1�	@ls�����F��e���
hb;p*��i����ٶ��������M޳��JQ8y��6��\��4���g^�$NB��w��鹯�}��O������F�R��������;�߷�n���V�넍�K��nc����������e��$�o�*������n�����_	|���M���/��Em��B����Vҝ�;4wh���/���)})�?jG��;��V�m�����.���Y��ɪ�)W�~�R4URr�,�h�,��'�$�IʙTV�qU#R���7��_��e��'���/y��VRD����������wm͉�]��_��[5�Oo��IEE�7_"�(*(ʯ5�Lϴ�$�� ���*�ʤG1�Y{���Ӛ��<ަ���{�5�{���9�F�q@gY8<�O��r�s�Fut�,F��m؅ҝ��C�D?O\�]�ڄs�>[x#<'�rv֒v�z��!�ˤ+�I�OS/�J����|��u:<�p���_>���gC�~��Ǩ������q���@�����$�����a6������_?������_���G���Ԯ�-�� �����q����_	��O���A p���?���O3��� �W�f��S��aJ�:T���6�I�=�3���pU'\�	Wu��#�?�F�?���'�T�����6@����_#����� �����M��i�~����J�Z�o���p������K�sZy��!���B���,k��t1}���o��ȏ�~޾��]�ݻ���O�}��E�y��UF����>_�>��I��L���:k��ֻ��y�D�h��t^���.��27��#�,	s�=虓Q����e�n'���3r���K���ϗ�O�{�>;^���L��D�ma��7�ۣ�eJ1'S����l�^,w{��>��a�&�*g��9r湄.[q�a�hGI�<�g��?F�ڙ&�C3�ib9�H�l9��{p��M݅����g���������O�`���?��k�C��64��!%�j4�������ߕ � �	� �������#@�U��,�`��.@����_#�����w�����@����A���hB��������Z��_��Lاb���43����ڿq�������s]���/����K�\�#����î�c[��'Ϊ����HJ�h���~�Q-���6gc}�Ǩ�/6��*��*�Q�K%/s�}w�,��L<�;,�:�c��=������PЅ⩮W�w$]
���_��Y���6>���kߺ��.���nI �s�i�[3�6��p;[��{R4Ў�u0K���}&��x�QJ����I.?n����*/]\�O��xc�������������������!��@����_��������J�$��/|�4>0���S��<�XH���$Cz�`d�4ɓ>bpG���	��(���j�3�����j�s,�C����w:��y��y*���>�G~G���or��ڞ����+��vyEs.��K�2[���zz��`�.7[R�+GY�Ĳ�����s�Ft�ɏ��Y��]��+�p�C�g}������֊&��P�ՇF�?��Ԇ����ǵ�����h�C�W~f�w4L�>jJ봝Dld!Gw�`��8��A	�+�]�f���S�$3P�R4Dc�3.��wF��%�D��tv)la�(#�S*;c�uI
��8�lk�)�"�S0�Bmߥ��{+�q���ք����Gp���_M������ �_���_����z�Ѐu���e��A�����?��꿈���?���#	^x�L��YƕX9�����Z��Ka����ގ2䪶�?r ���� ���}x�U��q���J�]�� �yZ�������SR+�-����a�[mT�z��ooW�%�:R�����6�y�������\��U���o���*r��\󁾛D_^�-����J�; L�-�x�b��ū�D��.��E�h��X�}/�C/��gL�5���2]��7Ls��-��w��5!!����o]1%Uk�v8��(7?��@l�fZW���BV�[$e����e�A_��Uȣ���D2B�oR�KM�>��,8:��ힶ_�^4h��é���W>��<��h.�x���������`��
4���O���������L�Ƣ*�����%�������������?��_*�8������Q�ν9N�T�y��yC�!�q��?���1���bC�c�;?M����>���>?s����u��z�Y�6�бO�ǂt���Z�1U2�N�&~���F�?�E��bY%��ӭ�q��˝Z��nHq��7�a:�ei6�˘��JDWY0�cWw��OO�m�0��M�ߊ&��8����*����-��W	�'T�����3�h�3w�?��U�j�ߛob�xo"����������`��"T������B;�!����7�������������u��8�c�u��b�N�8U։y7����˂�2������������������.��9�ބw�Eyu��s䴳h��ٲ�q�?��4�i��3�������ד1��������ͭ8�u�e�]!s�Ū�>��R.���V�-�u�� �^����~{��H~�8��9�ޑU�G����6���
���f����]���Sّ�+����i&�HJ���YHq^��]n�+�thm'N1�O���Ȣ5&���<m���S�B�٣�L�zw�a�E�x�47��������wU{p�oM�F����M���[�5��	���ךP-�� x�Є����7C@�_%��o����o����?迏�y���H@����_�����r��\�������_����
@�/��B�/��������������/��u����������4��	���I��*P�?��c�n �����p�w]���!�f ��������������5���v�������Y��U�*����
�*�?@��?��#?�F�?�������� ��!5��ϭ�������Eh��ZHhB��(�����J ��� ��� ��5�?��P�n�����mh�C8D�hD�� �����J ��� ���Po��@�A�c%h����������[�5���?����4��a��r4������ ��0����t	�Ch����?�_h��[��,O!��5 ��ϭ�����7����:4��q�*},d�,Gb܂��E@�\�S^	����x8�z�����{E���}�'��E��dp��k�_���H_+��Ӕ�K���^+N��*P����0��Ԣ��4F�x�3�;Ƙ�OC�3I�SҖài�8.G�!	��p�2�1F;�Y�mOb[��HI�����k�b���NB�w�NI���Iӣ= B�Tv���ܵ�p��2ե���݋��o�p�C�g}������֊&��P�ՇF�?��Ԇ����ǵ�����h�C�W~f�7H�>��]�[[m���"����u��e��S�ޗ��׹u��D�A�&��:���l.�K1�;O��3~n�{ԙE�0������ý.$�C�#5�(﷫�R���ފf��w����[p����w|o4a�����������?����@ցF���#�����5�7x�������^:&��t`����V'N���7���g�gmw�v��n����:yK���;���Ж|Z�{�����a]�B沿��j7�#K;�~4a�QFM�`i+f%�e��df��1;��F�32��Ƚ��D_��[��ӣ�n����]�~b�������t��e��	]4����9�E���2?�B��D*�!�t@Z�̠-�_]1%�˞}g����B��t�17Ws=��͹v��ȷ:���	����s��}/U�y�N�֜�4�u�t+<��5���hvo�����A�O����������_�š�[	>��{���?'��W�&�8� ���+�G��?%���WcQ���~��0� ��M����������s=!ӣy����5�������� �_x��3lI旯��qژ��4f�:΋���#��\��?;��-�K��D|�,M�γ�&_�K�4A�{��)�,?��~�X~�W��,��KϷȿ�.=]�^���ͺ�9���䯱%[��(�⴪�W�U��6Pg����Mڵ2&��
2��d�Q�����;Eʄń�N�i���-{�{��[3�ż�L�8�x�!��;�b�+��犩-�[�ܓ���y��vnr}��͔�ׂ,_l?�����.�KO�����(��ӟ�{�%��mYx!>ʶ��Nhפ[��8�Y{�޵�q�#�+Ȣ"�"���'�գM�|���x"��0���p� TB�!�Z�H���A=���3��m�B�sn����2�\l�&�5������~/h��������[���Oc>����.8�"<~A�w�6�����?�X,E��d}&�,�y�� ��f�G�	����������J�3��e&Z]7?���O|Q��a6��{ou{g���bN,]1�2�/W��V��ȕ�Z�������o��;�?4Ƃ�W���p�����U�
����k0�x������������˛��}��Ԝ;�,���b(�h���������A��2P����w3ؐ�y�?�����n���o��΋�7x��^l?�m��Iƹ�5�ow�##1����핉�̐���9����S�Y�o��kˀ��ٮS�g�2n1)��v/��]o|�����~/�����|��Ģ�F��,:-i�b���{A��yֶ��DPg�RАǾ�O��z8����t6�1��ᔥ����D�0�G�l�v� Ѯ�U���Ly��Kq.�$l��m��z�zb����.׿����&�?�����V�
��c*��1r�ĭ�0ׯh6�O{��y���;�&5�5��ϧprR�Δ'- ��=U����~����"����wh�t'��Nv�Ŏ�*�E@y���w��#��A�I��3D�\�ο7$�������������=?��O�2kO&̆Dk�C�����\����x%j"�90�Qu����n[ׂ��m�������R����X��i����k����K�4�-���3	�?�?j���_�HY��e `8(3���8��_��,	�*|k�GH�?���LԂ�֝Ʈ^K�V`������O��0h�ʥ�C��u�7���XY7�"
ا"�W�b�Q���ج,���&~N9?W��\4\������CW��+�q��7y:��8���h��ȯ+ᅽ��pR���,������j���D���pZ�n�l�����<st��
�u3�F���LЌ��(m�-9�bY�69�7�6�1�Q���\t^�Q<��(48.���}�Љ�g�և��;mJ���ao��]�ͷ5[P����`�mAVW��z��e�5�]��ڦ<�ju��f���ؽ��EK���v���n��9�]�S%�*[K��("�Y�{�B�W�K'p�/t�MI=����4Y�ĭ��a�O*����Y����Y�X�	i�?L�������E��N��	�?a�'�����o��?�C@&�����_���ё��C!��������[���*@�7���ߠ������y�/�g	|�4����)��tȄ��W�ߡ�gJ���W���E����������_��MT����>w ��������X�)%P�?ԅ@�?�?r��n��B���AF��B "-���������T��P��?�/�����_��H���B���}��L�����H�,�?d��#��U�
��� ������0��/m�u!���}��L�?��###�u!������C���*@��� �������`�'P����a�?b ��o��	��n���_��������D������a�?���_2��p����-�cn|�t@���/�_$��X�!%2��C���%vFkF�"Yf�[eҤK�Y�m�l�$�1,K/k��2�2���?o����ɂ�������Ë���U�qX����K�/W9[�|C�[�נ���eAxz�U^�#-��tl�9�M��)���&�/5�ny5�-k��k���x�!̻\2\�o�V�I�Gu2ȓy~;(���Z1\bM����/0]M�{+Zo�:m[C�pyy�Ǯ��8�$XG��ꗗx�S��x��P_�������U��`�7d����Y���������8D}�,�?�������R�I�69*�y��Z>*�?������vJ��=�]⿚8\�f�V���ŷ�zM��k�(�X8��~U,I��mV�Fa[�3U�%zq��l�PG�6#��o�B���]�ג������@��ڃ����/D&�A�2 �� ��������Ʉ���k�W��߬����Z���մC_�{�u��БE��ڿ���&?��=b����Lx������/;۰��m�p|c�uh�[�ix�ͫ��HӇ����l�'��؊F�-��;�7^9�dq�n�p�Kn+m���������o�bm�W�m�����<�?�*%lS�f�^�7�_���(���Mx�3�&�{�{��s�Ŧ���on�j�s�Wz���{�����I�#rw:5���DG6���*��*�s�^W&\T?�ä��H�c>"��ϋ�8�Fi@ZCJ�w��Z��k��A��_��$�����*޺�zL��(i|���ï�٤���=���F������Ӄ�5��M@�?�?j�������?������9�����������?��\�_,��Z�#��������1����B���@�OZ��}�c��`�G@�G����L�?�F�/��T@��`H�@���/��? #3��?"!�?s���C�G*|3���h��JXڷ��÷�ѱ)��13������n��I�����~��H+���]>�~$���܏$�{E���.���K��{{]�o�脽j�?R��1��+^۔�̴�Ѿ6+��fk�+���w�x{����	k�4O��Ôₒ5:�גj;����_�G�~/i�؍�_MOk��
��,9/�,j�f�)��X�H��|�)�剫a��~9gl������`�x���r�����z������j�^zk��A�b�9�sje�{�>R*U0�ƪW��
;_�O�A&���#��{�8�kq�@���/����Ȓ�?>�^�T�D������ ��������_h�
����=/��R�%�߷�˄��8�?"2��7^ oM&�����o���J2��E�Gu;�Ԫ��;�\�M��~�������Q$ۗ���XwW�zx��)�Q ���O9 �}�����O�ݚF�k%���ݨ��zE�4��Bg�=3(`J�ߔ��Q��y�8�HC:T�L��
=cQV����z �$�� ,I���n�E]N�G�U~^=�C(ܾ.fsSf\�m�a@��RP޻�=^�;���Ayݔ{���Cs{Mi/��<
HSg��n��N3���/��0��č�_��W* ��G}%������eA��č��E��4Ȏ�Se�5�"kY�fh�fΊ�NZ4�3�NФE�x�l҄a��[m�:˘�K��c�V��_�,����?a�:���?���9�[�듩Ǟ�����DS#�n/O�-�ZJ�$,�/���͘,��v��|M�#��
��^�V����h��EMk��3�9�2�8�j�d�4U�h,Z��1q |l�N8��?_K��������p�d�������������`��wI��?t�����V��B�۲�f8V),)m���n�Y�&ٙ<>r����1=�Ho�-�y^���w.�*Q��h��=qH���իd�0;6�ӮX�=�[�nP.Kt��&���hX�K����l��W��d���o����``�db��!� �� ���������,�?�.��Cķ��(������s�cF�m�<���-�^M����������~, �,�2 ������p�i���^^����;�v�n,�9,7��>��e�h,�%6<2Lo����bK͗։��5�T�J����ů�<}n����U;O>�<W�Mx�3�rQ�'�\g �QC�2_ ��0`�ԼRIvÁ��DE��em�a0�Z�Ux<��󛻼�F��?��t�����HO��m�g��}Q8�'���ť��U��Ɇ��;w�J��ʞ�V��D�����%�F�>g��h/ֆ�:�kթݙ&T�(N��_�0~���7Q��w�j�^�fC�q*���?I1E�?�͹m�����k����Ը���yc�p�ֱ����$��*�GA�?��~����Q;�.<$�����Y�9���:[9���	r6��ۅ�jc,s�~_���=���{�뚫ˮߌ������N���/6wy�Tr��O�d�}c^{�'wI(=ny�����#�y���y�d������o�Q���k����N�۸9��0g����g��7�i�UrǬ5w<`��>���=34�xs|9ɣ�ob\W�������c9Y�+ٳ�kz.��9c��f����ǯ��G��t{��9c�K��7<�����\����t�����]�?��������G�^��'�O���b�H���]��`%{����������<׫�m��v��rfɉFZ|	����=�_�3��s�;'nr�7R�2�5�x��|��\4�5�߹��ڹU�d����Ϝ;3�����\����4�֠���4?�$w��M�0Әor��}뵿c��4��n�����I���i�<���o/��ǧ/���]|��n�����4k��\�����+\�[z���qܯR|�_���gg�!��	����-�ݏ�^[h5%E~lϮ"�U��>��)���{ՅY$��A��ԟZ<Ԃ                 �_���+� � 