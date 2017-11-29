# README

## 概要

FreeStyle WikiはPerlによる拡張可能なWikiクローンです。FreeStyle Wikiは以下のような特徴を持っています。

* 徹底的にモジュール化されており、拡張性が高い
* PurePerlで実装されておりDBを使用しないため、多くのレンタルサーバに設置可能
* 日本語でのドキュメント作成に適した文法と機能
* 全ページ共通のヘッダ、フッタ、サイドバーを表示可能
* ファイルの添付が可能
* PDFの生成が可能
* tDiaryのテーマを使用可能
* サイトテンプレート機能によりデザインを大幅に変更することが可能
* ページの凍結機能に加え、簡単なユーザ認証機能を備えている
* mod_perlでも（一応）動作可能

## インストール

### サーバへの設置

アーカイブを展開し、そのままのフォルダ構造でサーバにアップロードします（docsディレクトリは不要）。
wiki.cgiはブラウザから起動されるスクリプトなのでパーミッションを実行可能にしておきます。
また、アップロードしたディレクトリの直下にbackup、attach、pdf、logディレクトリを作成します。
ディレクトリのうちdata、backup、attach、pdf、log、configディレクトリにはCGIから書き込みができるパーミッションに、
また、data、configディレクトリ内のファイルもCGIから書き込み可能なようにパーミッションを変更してください。

全体の構成は以下のようになります（数字はパーミッションの一例です）。
なお、サーバ上でシェルが利用可能な場合はインストールディレクトリの直下にあるsetup.shを実行することで
必要なディレクトリの作成やパーミッションの設定をを自動的に行うことができます。
```
-+-/attach (添付ファイル) 707
 |
 +-/pdf (PDFファイル) 707
 |
 +-/tmpl (テンプレート) 
 |
 +-/backup (バックアップファイル) 707
 |
 +-/data (データファイル) 707
 |  |
 |  +-*.wiki (デフォルトのデータファイル) 606
 |
 +-/log (ログファイル) 707
 |
 +-/config (設定ファイル) 707
 |  |
 |  +-*.dat (デフォルトの設定ファイル) 606
 |
 +-/theme (テーマ)
 |
 +-/plugin (プラグイン)
 |
 +-/lib (ライブラリ)
 |
 +-wiki.cgi (CGIスクリプト本体) 705
 |
 +-setup.dat (設定ファイル)
```
設定が完了したらブラウザからwiki.cgiを呼び出してみてください。
FrontPageが表示されればとりあえず設置は成功です。

### setup.datの設定

データ保管場所などFreeStyle Wikiの基本的な設定はsetup.datを編集することで行います。

FreeStyle Wikiでは、ページが変更された場合に管理者にメールで通知する機能があります。
この機能を有効にするにはsetup.datの設定内容にsendmailのパスかSMTPサーバのホスト名を設定します。

また、デフォルトではバックアップは一世代のみですが、backupというパラメータにバックアップする世代数を指定することができます。
0を指定すると無制限にバックアップを行います。
世代バックアップを行う場合、画面上部の「差分」メニューを選択すると過去の編集履歴が表示され、
それぞれについて現在のソースとの差分を閲覧することができます。

また、rssやamazonなど、一部のプラグインはプログラム中からHTTPで外部のサーバに接続します。
プロキシを使用している場合はproxy_host、proxy_port、proxy_user、proxy_passを設定しておく必要があります
（proxy_userとproxy_passは認証が必要な場合のみ）。

### セキュリティ

上記で解説したインストール方法ではsetup.datや各種データを保存しているディレクトリをHTTPで参照できてしまいます。
セキュリティ上問題になるようであれば.htaccessを使用してアクセス制限を行ってください。
```
<FilesMatch "\.(pm|dat|wiki|log)$">
  deny from all
</FilesMatch>
```
なお、データディレクトリに関してはHTTPでは見えない場所に配置することも可能です。
その場合はsetup.datのディレクトリ指定部分を変更してください。

### バージョンアップ時の設置方法

設置ディレクトリ直下にあるsetup.dat、dataディレクトリ、backupディレクトリ、
pdfディレクトリ、logディレクトリ、configディレクトリ以外のファイルおよびディレクトリをいったん削除し、
配布ファイルで置き換えてください。
また、dataディレクトリ内のhelp.wikiはヘルプで表示されるページですのでこれも最新版のファイルで上書きしてください。

setup.datはできるだけバージョン間で相違のないよう配慮していますが、
止むを得ずバージョンアップ時に内容を変更する必要がある場合があります。
できれば最新のファイルで上書きしたあと、設定内容を修正するようにしてください。

また、3.4.0以降ではバージョンアップによって管理画面での設定項目が追加されている場合があります。
一度管理ユーザにてログインし、設定の更新を行ってください。

### データのバックアップ方法

dataディレクトリ、attachディレクトリ、configディレクトリをコピーしてください。
差分表示が必要であればbackupディレクトリ、PDFも必要であればpdfディレクトリもコピーしてください
（PDFファイルはPDFアンカ押下時に生成することができるのでバックアップしなくても構いません）。

ログは、デフォルトではlogディレクトリにaccess.log（アクセスログ）、freeze.log（凍結用のログ）、attach.log（添付ファイルのログ）が
出力されていますので、必要に応じてこれらもコピーしておいてください。

### mod_perlで使用する場合

Ver3.4.1よりmod_perlにも対応しています。
wiki.cgiの先頭部分を編集し、chdirの引数にFSWikiのインストールディレクトリを指定してください。
例えばFSWikiをC:/Apache/htdocs/fswikiに配置した場合は以下のようになります。
```perl
BEGIN {
  if(exists $ENV{MOD_PERL}){
    # カレントディレクトリの変更
    use Cwd;
    chdir("C:/Apache/htdocs/fswiki");
```
3.5.1以降はApache::Registory環境下でも完全に動作することを確認していますが、
それ以前にバージョンでは差分表示やPDF生成など一部の機能の動作に支障があります
Apache::PerlRun環境下であれば問題ありません。

## FSWikiの機能

### 文法

FreeStyleWikiの文法についてはインストール後にメニューからヘルプを選択することで表示されるHelpページを参照してください。

3.5.3からはプラグインによってFSWikiの基本文法以外の文法でも編集が可能になっています。
管理画面からformatプラグインをアクティベートし、サイドバーなどにselect_formatプラグインを入れてみてください。
編集者が自分の好きな文法を選ぶことができます。

現状ではYukiWiki、Hikiの文法に対応しています。
ただしプラグインの記法やプラグイン名についてはFSWikiのものを使いますのでご注意ください。

### 特殊なページ名

Header、Footer、Menuというページを作成するとそれぞれヘッダ、フッタ、サイドバーが表示されます。
また、EditHelperというページを作成するとページの作成・編集画面に表示されますので
編集時のヘルプになるような内容を記述しておくとよいでしょう。

Template/ではじまるページを作成しておくと、ページの作成画面でコンボボックスからページのテンプレートとして選択することができます。
定型的なページを多数作成する場合などはテンプレートを作成しておくと便利です。

### テーマ

FreeStyleWikiはtDiaryのテーマを使って見た目を変更することができます。
tDiaryのテーマはtDiaryのWebサイトから入手可能です。
新しいテーマをインストールする場合、FreeStyleWikiのテーマディレクトリ配下に以下のような感じで配置します。

/theme
  |
  +-/default
  |   |
  |   +-default.css
  |
  +-/hoge
      |
      +-hoge.css
配置したテーマは管理画面の「スタイル設定」で選択することができます。

### サイトテンプレート

CSSだけでは思い通りのデザインを実現できないという場合のためにサイトテンプレート機能が提供されています。

サイトテンプレートはHTML::Templateのテンプレートを拡張したもので、tmpl/site配下に配置されています。
デフォルトでは defaultディレクトリに入っているものが使用されますが、
新たに独自のテンプレートを作成する場合、hoge.tmpl、 hoge_handyphone.tmplという２種類のテンプレートを用意し、
tmpl/site/hogeディレクトリを作成し、その中に配置します。
```
/tmpl
  |
  +-/site
     |
     +-/default
     |  |
     |  +-default.tmpl
     |  |
     |  +-default_handyphone.tmpl
     |
     +-/hoge
        |
        +-hoge.tmpl
        |
        +-hoge_handyphone.tmpl
```
配置したサイトテンプレートは管理画面の「スタイル設定」で選択することができます。

### 管理画面

画面上部のログインメニューから管理者ユーザでログインすると管理画面を使用することができます。
デフォルトの管理ユーザはID:admin、 Pass:adminになっています。ログイン後、パスワードを変更してください。
管理画面ではページの凍結や削除、ユーザの管理、Wikiの動作設定などを行うことができます。

ユーザには管理ユーザと一般ユーザの二種類が存在します。管理ユーザは共に凍結されたページの編集を行うことができます。
管理ユーザと一般ユーザはページの作成や編集を禁止されている場合でも作成、編集を行うことができます。
また、プラグインの中にはログインしている場合のみエントリフォームが表示されたりするものもあります。
ただし、管理画面を使用することができるのは管理ユーザだけです。一般ユーザは管理画面を使用することはできません。

### プラグイン

FreeStyleWikiのディストリビューションには様々なプラグインが含まれており、
インストール直後に使用可能な状態になっています。
詳細についてはpluginhelpで表示されるヘルプを参照してください。

管理画面でパッケージごとにプラグインを使用するかどうかを設定することができますが、
coreパッケージを使用不可にするとFSWiki自体が動作不可能な状態になります。
また、adminパッケージを使用不可にするとログイン機能、管理機能が使用できなくなります。ご注意ください。

### WikiFarmの利用について

FSWikiでは１つのWikiで複数のWikiサイトを運用することができる「WikiFarm」という機能を実装しています。
FSWikiのWikiFarmはデフォルトのWikiサイトをルートとしたツリー構造を形成します。

* ルートのWiki
** 子Wiki1
** 子Wiki2
*** 孫Wiki

この機能を利用するためには管理画面の「WikiFarmの設定」から「Farmを使用するかどうか」で「使用する」を選択します
(他にWikiサイトの作成を誰に許可するかといった設定を行うこともできます)。
画面上部のメニューに「Farm」と表示されるので、ここをクリックすると、

* 現在のWikiサイトの配下に存在するWikiサイトの一覧
* 新規Wikiサイトの作成フォーム(作成権限を持っている場合のみ)

が表示されます。
作成フォームに新たなWikiサイトの名前と、管理者のユーザID、パスワードを入力してWikiサイトを作成することができます。
最初にFrontPageの作成画面が開くので任意の内容を記述してFrontPageを作成します。
あとは通常通りに利用することができます。

## プラグイン開発

###プラグインのインストール

プラグインはパッケージごとにディレクトリを作成し、pluginディレクトリに配置します。
プラグインを有効にするには管理画面から「プラグインの設定」で該当するプラグインにチェックを入れます。

プラグインを開発する場合、パッケージごとにまとめてパッケージ名::Installというモジュールを作成し、
そのモジュール内でインストール処理を行うようにします。
```perl
package plugin::test::Install;
sub install {
  my $wiki = shift;
  $wiki->add_inline_plugin("hello","plugin::test::TestPlugin");
}
```
有効になっているパッケージは自動的ににplugin::test::Installモジュールのinstallメソッドが呼び出され、プラグインのインストールが行われます。

### アクションハンドラ

アクションハンドラプラグインはactionというリクエストパラメータによってクライアントへのレスポンスを行うプラグインです。
アクションハンドラプラグインはdo_actionメソッドを実装したクラスでなくてはなりません。
また、戻り値として、表示する内容（HTML）を返すようにします。
```perl
sub do_action {
  my $self = shift;
  my $wiki = shift;
  return "アクションハンドラプラグインからの出力";
}
```
アクションハンドラの登録はインストールスクリプト中でWiki#add_handlerメソッドによって行います。
```perl
$wiki->add_handler("EDIT","plugin::core::EditPage");
```
管理者のみ使用可能なアクションハンドラはWiki#add_admin_handlerメソッドによって登録します。

このメソッドによって登録されたアクションハンドラは管理者としてログインしている場合のみ実行可能になり、それ以外の場合はエラーメッセージを表示します。
```perl
$wiki->add_admin_handler("ADMINPAGE","plugin::admin::AdminPageHandler");
```

### フックプラグイン

フックプラグインはある契機で特定のメソッドを実行するプラグインです。
メニューのON/OFF切り替えや、ページ保存時などのタイミングで特殊な処理を行う場合に使用します。
フックプラグインはhookメソッドを実装したクラスでなくてはなりません。

hookメソッドの第３引数には起動されたフックの名前が渡されます。
１つのクラスで複数の処理を実装する場合はこの変数を見て処理を分けます。
また、第４引数以降にはWiki#do_hookメソッド呼び出し時に指定されたパラメータ（呼び出し側に依存）が渡されます。
独自にフックを定義してパラメータを渡したい場合に使用してください。
```perl
sub hook {
  my $self   = shift;
  my $wiki   = shift;
  my $name   = shift;
  my @params = @_;
  ...
}
```
フックプラグインの登録はインストールスクリプト中でWiki#add_hookメソッドによって行います。
```perl
$wiki->add_hook("show","plugin::core::BBS");
```

フックには以下ものが存在します。
* show - ページの表示前に呼ばれます。
* save_before - ページの保存処理前に呼ばれます。
* save_after - ページの保存終了後に呼ばれます（ページ削除時は呼ばれません）。
* delete - ページの削除後に呼ばれます。
* create_wiki - WikiFarmで新しくWikiが作成された場合に呼ばれます。
* remove_wiki - WikiFarmでWikiが削除された場合に呼ばれます。
* initialize - CGIの起動時に呼ばれます。プラグインごとに初期化処理が必要な場合などはこのフックに登録してください。

また、これ以外にプラグインによっては独自にフックを定義している場合があります。

### インライン

インラインプラグインはWiki文書中に
```
{{プラグイン名 [引数1,引数2...]}}
```
で埋め込むことで、特殊な出力を行うプラグインです。
インラインプラグインはinlineメソッドを実装したクラスでなくてはなりません。
戻り値としてWiki形式の文字列またはHTMLを返すようにします。
Wiki形式のテキストを返す場合はPDFにも出力が反映されます。

以下にHTMLを返すプラグインの例を示します。
```perl
sub inline {
  my $self = shift;
  my $wiki = shift;
  return "<B>簡単なプラグインです。</B>";
}
```
以下はWiki形式のテキストを返すプラグインの例です。
```perl
sub inline {
  my $self   = shift;
  my $wiki   = shift;
  my $parser = shift;
  return "[[FrontPage]]";
}
```

インラインプラグインの登録はインストールスクリプト中でWiki#add_inline_pluginメソッドによって行います。
第一引数には実際にWikiページを記述する際にプラグインを指定するための文字列、
第二引数にはプラグインのクラス名、
第三引数にはそのプラグインの返す文字列に応じてHTMLまたはWIKIを指定します。
```perl
$wiki->add_inline_plugin("edit","plugin::core::Edit","HTML");
```

### パラグラフ

パラグラフプラグインはWiki文書中に
```
{{プラグイン名 [引数1,引数2...]}}
```
で埋め込むことで、特殊な出力を行うプラグインです。
インラインプラグインと違って１行にプラグインしか記述できず、Pタグの補完も行われません。
テーブルやフォーム、リストなどを出力するプラグインをパラグラフプラグインとして実装します。
パラグラフプラグインはparagraphメソッドを実装したクラスでなくてはなりません。

paragraphメソッドは実装方法自体はインラインプラグインと同様です。
以下にHTMLを返す場合の例を示します。Pタグは補完されないので必要に応じてプラグイン側でつけてやる必要があります。
```perl
sub paragraph {
  my $self = shift;
  my $wiki = shift;
  return "<p>パラグラフプラグインです。</p>";
}
```

以下はWiki形式の文字列を返す場合の例です。
```perl
sub paragraph {
  my $self   = shift;
  my $wiki   = shift;
  return "*[[FrontPage]]\n*[[Help]]\n";
}
```

パラグラフプラグインの登録はインストールスクリプト中でWiki#add_paragraph_pluginメソッドによって行います。第一引数には実際にWikiページを記述する際にプラグインを指定するための文字列、第二引数にはプラグインのクラス名、第三引数にはそのプラグインの返す文字列に応じてHTMLまたはWIKIを指定します。
```perl
$wiki->add_paragraph_plugin("bbs","plugin::bbs::BBS","HTML");
```

### ブロック

ブロックプラグインは複数行の引数を取ることができるパラグラフプラグインです。
以下のようにして使用します。引数3の部分は複数行に渡って記述することができます。
```
{{プラグイン名 引数1,引数2,
引数3
}}
```
ブロックプラグインではparagraph()メソッドの代わりにblock()メソッドを実装します。
複数行の引数が第一引数として、それ以外の引数は第二引数以降に渡されてきます。
```perl
sub block {
  my $self = shift;
  my $wiki = shift;
  my $text = shift;
  return "<p>".Util::escapeHTML($text)."</p>";
}
```
パラグラフプラグインの登録はインストールスクリプト中でWiki#add_block_pluginメソッドによって行います。
第一引数には実際にWikiページを記述する際にプラグインを指定するための文字列、
第二引数にはプラグインのクラス名、
第三引数にはそのプラグインの返す文字列に応じてHTMLまたはWIKIを指定します。
```perl
$wiki->add_block_plugin("pre","plugin::core::PRE","HTML");
```

### エディットフォーム

エディットフォームプラグインはページの編集画面に表示されるプラグインです。
エディットフォームプラグインはeditformメソッドを実装したクラスでなくてはなりません。
editformメソッドは編集画面に表示するHTMLを返却するよう実装します。

エディットフォームプラグインの登録はインストールスクリプト中でWiki#$wiki->add_editform_pluginメソッドによって行います。
```perl
$wiki->add_editform_plugin("plugin::core::EditHelper",0);
```
第３引数にはそのプラグインの表示優先度を指定します。この値が大きいほど上位に表示されます。

### フォーマット

フォーマットプラグインはFSWiki以外のWikiの書式での編集を行なうためのプラグインです。
フォーマットプラグインは以下のメソッドを実装していなくてはいけません。

* convert_from_fswikiメソッド - FSWikiから各フォーマットへの変換
* convert_from_fswiki_lineメソッド - FSWikiから各フォーマットへの変換（インライン要素のみ）
* convert_to_fswikiメソッド - 各フォーマットからFSWiki形式への変換
* convert_to_fswiki_lineメソッド - 各フォーマットからFSWiki形式への変換（インライン要素のみ）

フォーマットプラグインはインストールスクリプト中で以下のようにして登録を行ないます。
```perl
$wiki->add_format_plugin("Hiki","plugin::format::HikiFormat");
```

### メニューアイテム

Wikiオブジェクトのadd_menuメソッドで画面上部のメニューアイテムを追加することができます。
```perl
$wiki->add_menu(名称,URL,優先度);
```
第３引数にはそのプラグインの表示優先度を指定します。この値が大きいほど左側に表示されます。
また、URLを省略するか、空文字列を設定すると無効なメニューが登録されます。
既に同じ名前のアイテムが登録されていた場合は上書きされます。

### 管理者メニュー

Wikiオブジェクトのadd_admin_menuメソッドで管理者ログイン時のメニューを追加することができます。
このメニューが表示されるのは管理者がログインした場合のみです。一般ユーザがログインしても表示されません。
また、管理者メニューから呼び出されるアクションハンドラはadd_admin_handlerで登録しておくとログインチェック、権限チェックが自動化されます。
```perl
$wiki->add_admin_menu(名称,URL);
```


### THANKS

FreeStyle Wikiでは以下のライブラリを使用しています。
これらについての著作権は原作者が持ちます。
有用なライブラリを無償で提供してくださっている作者の皆様に感謝します。

[PDFJ](http://hp1.jonex.ne.jp/~nakajima.yasushi/)
> PDFの生成にPDFJを使わせていただいています。Pure Perlで実装されており、手軽にPDFを生成することができる素晴らしいライブラリです。

[TeX::Hyphen](http://search.cpan.org/author/JANPAZ/TeX-Hyphen-0.140/)
> PDFJで欧文のハイフネーションを行うために使用しているそうです。

[Algorithm::Diff](http://search.cpan.org/author/NEDKONZ/Algorithm-Diff-1.15/)
> 差分の表示に使用してます。

[HTML::Template](http://search.cpan.org/author/SAMTREGAR/HTML-Template-2.6/)
> シンプルなHTMLテンプレートエンジンです。

[Jcode](http://search.cpan.org/author/DANKOGAI/Jcode-0.83/)
> 3.4.1よりjcode.plの代わりに使用しています。

[libwww](http://search.cpan.org/author/GAAS/libwww-perl-5.69/)
> RSSの取得などHTTP通信に使用しています。Active Perlでは不要です。

[libnet](http://search.cpan.org/author/GBARR/libnet-1.16/)
> Net::SMTPでのメール送信に使用しています。

[MIME::Base64](http://search.cpan.org/author/GAAS/MIME-Base64-2.20/)
> メール送信時のMIMEエンコードに使用しています。Perl 5.8.0以降およびActive Perlでは不要です。

[URI](http://search.cpan.org/author/GAAS/URI-1.23/)
> libwwwが内部的に使用しているようです。Active Perlでは不要です。

[CGI::Session](http://search.cpan.org/author/SHERZODR/CGI-Session-3.94/)
> ログイン機能のセッション維持に使用しています。

[Digest::MD5](http://search.cpan.org/author/GAAS/Digest-MD5-2.25/)
> CGI::Sessionが内部的にセッションIDの生成に使用しています。Perl 5.8.0およびActive Perlでは不要です。

[Digest::Perl::MD5](http://search.cpan.org/author/DELTA/Digest-Perl-MD5-1.5/)
> Digest::MD5のPure Perl実装です。Perl 5.8.0およびActive Perlでは不要です。

[tDiary](http://www.tdiary.org/)
> 突っ込み、スタイル、プラグインなど斬新な機能を多数搭載したRubyによるWeb日記システム。tDiary用のスタイルを使用させていただいてます。

# ライセンス

FreeStyle WikiはGNU GPLライセンスの元で配布、改変が可能です。
FreeStyle Wikiに組み込むプラグインを公開される方はGPLコンパチのライセンスを推奨しますが、その他のライセンスを宣言されても構いません。
また、パッチに関しては本体および標準添付のプラグインにあてるものはGPL、プラグインにあてるものはプラグインのライセンスにしたがうものとします。

# 作成者

Copyright 2002-2017 FreeStyle Wiki Development Team
