echo Start image analyse
cd C:\Users\Kaining\Dropbox\daily
call conda activate trl
python "C:\Users\Kaining\Dropbox\daily\autoModel.py"
echo copy images to kaining dir
move C:\Users\Kaining\Dropbox\Apps\RootCamPy\cam1\L00\*.* C:\Users\Kaining\Pictures\108
