#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Preparando para realiar o SKULL STRIPPING =============="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

3dAFNItoNIFTI urd_T1_"$i"+orig

echo
echo
done 
echo "Para a próxima etapa recomenda-se realizar o SKULL STRIPPING das imagens manualmente no MRIcron. Lembre-se de salvar como Analyze a mascara com o nome: "
echo "lurd_T1_<cod_sub>"
echo "Em seguida use o MRIron para converter a mascara para o formato NIFTI. Salve com o seguinte nome:"
echo "lurd_T1_<cod_sub>.nii.gz"
echo
echo "Para reiniciar o pre-processamento das imagens quando terminar o SS execute novamente:"
echo ">. run"
echo "Digite 2 e pressione enter"


