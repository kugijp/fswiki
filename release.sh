#!/bin/sh
###############################################################################
#
# FSWiki��꡼���ѥ�����ץ�
#
###############################################################################
if [ $# -lt 1 ]; then
  echo "./release.sh version"
  exit 1
fi

#==============================================================================
# �С���������
#==============================================================================
VERSION=$1

#==============================================================================
# �ƥ�ݥ��ǥ��쥯�ȥ�̾��zip�ե�����̾��
#==============================================================================
DIR_NAME="wiki$VERSION"

#==============================================================================
# �ǥ��쥯�ȥ꤬������Ϻ��
#==============================================================================
if [ -e $DIR_NAME ]; then
  echo "delete temp directory..."
  rm -rf $DIR_NAME
fi

#==============================================================================
# zip�ե����뤬������Ϻ��
#==============================================================================
if [ -e $DIR_NAME.zip ]; then
  echo "delete zip file..."
  rm $DIR_NAME.zip
fi

#==============================================================================
# ��ȥǥ��쥯�ȥ�����
#==============================================================================
echo "create temp directory..."
mkdir $DIR_NAME

#==============================================================================
# ���ƤΥե������ƥ�ݥ��ǥ��쥯�ȥ�˥��ԡ�
#==============================================================================
echo "copy to temp directory..."
cp ./wiki.cgi $DIR_NAME
cp ./setup.dat $DIR_NAME
cp ./setup.sh $DIR_NAME
cp -r ./config $DIR_NAME
cp -r ./data $DIR_NAME
cp -r ./docs $DIR_NAME
cp -r ./lib $DIR_NAME
cp -r ./plugin $DIR_NAME
cp -r ./theme $DIR_NAME
cp -r ./tmpl $DIR_NAME

#==============================================================================
# zip�ե�����˰���
#==============================================================================
echo "create zip file..."
find ./$DIR_NAME/docs    \! -path '*/CVS*' -exec zip $DIR_NAME.zip {} \;
find ./$DIR_NAME/lib     \! -path '*/CVS*' -exec zip $DIR_NAME.zip {} \;
find ./$DIR_NAME/plugin  \! -path '*/CVS*' -exec zip $DIR_NAME.zip {} \;
find ./$DIR_NAME/theme   \! -path '*/CVS*' -exec zip $DIR_NAME.zip {} \;
find ./$DIR_NAME/tmpl    \! -path '*/CVS*' -exec zip $DIR_NAME.zip {} \;

zip $DIR_NAME.zip ./$DIR_NAME/config/config.dat
zip $DIR_NAME.zip ./$DIR_NAME/config/farmconf.dat
zip $DIR_NAME.zip ./$DIR_NAME/config/mime.dat
zip $DIR_NAME.zip ./$DIR_NAME/config/plugin.dat
zip $DIR_NAME.zip ./$DIR_NAME/config/user.dat
zip $DIR_NAME.zip ./$DIR_NAME/config/usercss.dat

zip $DIR_NAME.zip ./$DIR_NAME/data/FrontPage.wiki
zip $DIR_NAME.zip ./$DIR_NAME/data/Help.wiki
zip $DIR_NAME.zip ./$DIR_NAME/data/Help%2FFSWiki.wiki
zip $DIR_NAME.zip ./$DIR_NAME/data/Help%2FHiki.wiki
zip $DIR_NAME.zip ./$DIR_NAME/data/Help%2FYukiWiki.wiki
zip $DIR_NAME.zip ./$DIR_NAME/data/PluginHelp.wiki

zip $DIR_NAME.zip ./$DIR_NAME/setup.sh
zip $DIR_NAME.zip ./$DIR_NAME/setup.dat
zip $DIR_NAME.zip ./$DIR_NAME/wiki.cgi

#==============================================================================
# ��ȥǥ��쥯�ȥ����
#==============================================================================
echo "deletie temp directory..."
rm -rf $DIR_NAME

echo "complete."
