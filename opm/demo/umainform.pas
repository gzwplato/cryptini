unit umainform;
{$DEFINE USE_DCPCRYPT} // Delete this if you don't have the DCrypt library
                       // It enables the 'Encrypt INI' and 'Decrypt INI' menu entries

{ Test App for cryptini unit

  Copyright (C) 2016 Gordon Bamber minesadorada@gmail.com
  Encrypt/Decrypt INI code: @Ericktux (http://forum.lazarus.freepascal.org)
  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
{$mode objfpc}{$H+}

interface

uses
  SysUtils, LazFileUtils, FileUtil, Forms, Dialogs, StdCtrls, Controls, Classes,
  Buttons, ExtCtrls, Menus, ucryptini, umemoform, ukeydialog, uInputSectionValuesForm;

const
    {$IFDEF WINDOWS}
  C_OS = 'win';
    {$ELSE}
  C_OS = 'linux';
    {$ENDIF}
    {$IFDEF CPU32}
  C_BITNESS = '32';
    {$ELSE}
  C_BITNESS = '64';
    {$ENDIF}
  C_PFX = C_OS + C_BITNESS;
  C_KEYPHRASE = 'Rudolph the Red Nosed Reindeer: had a very shiny nose';

  C_VERSION = '1.0.0.5';

type

  { Tmainform }

  Tmainform = class(TForm)
    cmd_DeleteValue: TButton;
    cmd_EraseSection: TButton;
    cmd_Read: TButton;
    cmd_ReadSectionValues: TButton;
    cmd_ShowINI: TButton;
    cmd_Close: TBitBtn;
    cmd_ValueExists: TButton;
    cmd_Verify: TButton;
    cmd_VerifySectionValues: TButton;
    cmd_Write: TButton;
    cmd_WriteSection: TButton;
    cmb_Sections: TComboBox;
    edt_Value: TEdit;
    edt_Section: TEdit;
    edt_Ident: TEdit;
    edt_Integer: TEdit;
    GroupBox1: TGroupBox;
    Grp_DefaultValueTests: TGroupBox;
    lbl_Value: TLabel;
    lbl_Section: TLabel;
    lbl_Ident: TLabel;
    lbl_Integer: TLabel;
    MainMenu1: TMainMenu;
    mnu_optionsDecryptINIFile: TMenuItem;
    mnu_optionsEncryptINIFile: TMenuItem;
    mnu_helpAbout: TMenuItem;
    mnu_helpHelp: TMenuItem;
    mnu_help: TMenuItem;
    mnu_optionsEncryptionKey: TMenuItem;
    mnu_fileClose: TMenuItem;
    mnu_options: TMenuItem;
    mnu_file: TMenuItem;
    rg_Encryption: TRadioGroup;
    rg_SectionHashing: TRadioGroup;
    procedure cmb_SectionsSelect(Sender: TObject);
    procedure cmd_DeleteValueClick(Sender: TObject);
    procedure cmd_ReadClick(Sender: TObject);
    procedure cmd_ReadSectionValuesClick(Sender: TObject);
    procedure cmd_ShowINIClick(Sender: TObject);
    procedure cmd_ValueExistsClick(Sender: TObject);
    procedure cmd_VerifyClick(Sender: TObject);
    procedure cmd_VerifySectionValuesClick(Sender: TObject);
    procedure cmd_WriteClick(Sender: TObject);
    procedure cmd_EraseSectionClick(Sender: TObject);
    procedure cmd_WriteSectionClick(Sender: TObject);
    procedure edt_IntegerEditingDone(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mnu_fileCloseClick(Sender: TObject);
    procedure mnu_helpAboutClick(Sender: TObject);
    procedure mnu_helpHelpClick(Sender: TObject);
    {$IFDEF USE_DCPCRYPT}
    procedure mnu_optionsDecryptINIFileClick(Sender: TObject);
    procedure mnu_optionsEncryptINIFileClick(Sender: TObject);
    {$ENDIF}
    procedure mnu_optionsEncryptionKeyClick(Sender: TObject);
    procedure rg_EncryptionSelectionChanged(Sender: TObject);
    procedure rg_SectionHashingSelectionChanged(Sender: TObject);
  private
    IniFilePath: string;
    INI: TCryptIniFile;
    sStoredMD5Hash: string;
    sVersion: string;
  public

  end;

var
  mainform: Tmainform;

implementation

{$R *.lfm}

{ Tmainform }

procedure Tmainform.FormCreate(Sender: TObject);
begin
  IniFilePath := ProgramDirectory + 'test' + C_PFX +
{$IFDEF WINDOWS}
    '.' +
{$ENDIF}
    'ini';

{$IFNDEF USE_DCPCRYPT}
mnu_optionsEncryptINIFile.Enabled:=False;
mnu_optionsDecryptINIFile.Enabled:=False;
{$ENDIF}

  {DEBUG - delete any old versions of the INI
  if FileExists(IniFilePath) then
    DeleteFile(IniFilePath);
  }
  Caption := Application.Title;
  Icon := Application.Icon;
  INI := TCryptIniFile.Create(IniFilePath);
  // Create encryption key for secure Read/WriteInteger
  INI.KeyPhrase := C_KEYPHRASE;

  // Or set INI.Key directly (weaker encryption)
  // DEBUG: ShowMessageFmt('Key set to %d',[INI.Key]);

  // method: WriteIdent(Const sAuthor,sCopyright,sLicense,sContact:String;Force: boolean=False);
  // No need to do this each time
  // Comment this line out once you have the MD5Hash from the ini file
  if INI.IsVirgin then // DeFlowers
  begin
    INI.WriteIdent('Gordon Bamber', '(c)2016', 'LGPL', 'minesadorada@gmail.com', True);
    // MD5 for this is: 92abf0deecbb25c435bff507a396d92a
  end
  else
  // someone tampered with the ident?
  if not INI.VerifyIdent('92abf0deecbb25c435bff507a396d92a') then
  begin
    ShowMessage('Program ident has been tampered with.' + LineEnding +
      'Restoring correct version.');
    // Last parameter (Optional) forces a rewrite even if FirstRun = 0
    INI.WriteIdent('Gordon Bamber', '(c)2016', 'LGPL', 'minesadorada@gmail.com', True);
  end;

  sVersion := C_VERSION;
  sStoredMD5Hash := '32-character MD5Hash string';
  INI.ReadSections(cmb_Sections.Items);
  cmb_Sections.ItemIndex := 0;
  edt_Section.Text := 'TestSection';
end;

procedure Tmainform.FormShow(Sender: TObject);
begin
  // Test the IsVirgin function
  if INI.IsVirgin then
    ShowMessage('First time run of this app');
end;

procedure Tmainform.mnu_fileCloseClick(Sender: TObject);
begin
  Close;
end;

procedure Tmainform.mnu_helpAboutClick(Sender: TObject);
// Shows ReadUnencryptedString method
var
  s: string;
begin
  s := Application.Title + LineEnding + LineEnding;
  s += INI.ReadUnencryptedString('ProgramInfo', 'Copyright', '');
  s += ' by ' + INI.ReadUnencryptedString('ProgramInfo', 'Author', '') + LineEnding;
  s += 'Licence: ' + INI.ReadUnencryptedString('ProgramInfo', 'License', '') +
    LineEnding;
  s += 'Made with LCL v ' + INI.ReadUnencryptedString('ProgramInfo', 'LCL Version', '');
  s += ' FPC v ' + INI.ReadUnencryptedString('ProgramInfo', 'FPC Version', '') +
    LineEnding;
  s += 'Compiled ' + INI.ReadUnencryptedString('ProgramInfo', 'Last Compiled', '');
  s += ' for ' + INI.ReadUnencryptedString('ProgramInfo', 'Target System', '') +
    LineEnding;
  s += 'CryptINI Version: ' + INI.CryptINIVersion + LineEnding;
  s += 'Cipher in use: ' + INI.CipherType + '.  Hash in use: ' + INI.HashType + '.';
  MessageDlg('About ' + Application.Title, s,
    mtInformation, [mbOK], 0);
end;

procedure Tmainform.mnu_helpHelpClick(Sender: TObject);
begin
  with ShowINIForm do
  begin
    MakeReadOnly;
    Caption := 'Help for ' + Application.Title;
    Memo_INI.Lines.Clear;
    Memo_INI.Lines.Add('This test application is to test the Tcryptini class V ' +
      INI.CryptINIVersion);
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add(
      'The obvious test is to click Write, Read then Verify, which uses automatic values.');
    Memo_INI.Lines.Add(
      'Verification of an entry involves reading the value with its built-in MD5Hash');
    Memo_INI.Lines.Add(
      'and then computing a new MD5Hash from the value, and comparing it with the built-in one.');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add(
      'Additionally, if SectionHashing=TRUE then every time a new entry is added to the section,');
    Memo_INI.Lines.Add(
      'all the entries are combined into a section hash, and it is written/updated as an automatic');
    Memo_INI.Lines.Add(
      'new/updated entry: MD5Hash=<32-character hash> ,which you can use in the VerifySection(MD5Has Value) method');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add(
      'There is a new method WriteSectionValues(Section,Strings) which is absent in TINIFile that you may find useful.');
    Memo_INI.Lines.Add(
      'WriteSectionValues works with PlainText TRUE/FALSE and SectionHashing TRUE/FALSE.');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add('Other new methods are EncryptINI and DecryptINI.  This acts on the whole INI file,');
    Memo_INI.Lines.Add('with password, new file extension and auto-deleting the "old" file as optional parameters.');
    Memo_INI.Lines.Add('The defaults are the INI.KeyPhrase, ".enc" and no auto-deletion.');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add(
      'Wnen property PlainText=TRUE then TCryptINI behaves just as TINIFile did');
    Memo_INI.Lines.Add(
      'This property can be changed on-the-fly to enable a mixed Crypted/Plaintext INI file.');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add(
      'Note that Integer keys have an automatic "' + INTEGER_MARKER + '" added in encrypted mode.');
    Memo_INI.Lines.Add('This is so that the ReadSection method can identify them in Encrypted mode.');
    Memo_INI.Lines.Add(
      '(Integers are double-encrypted for extra security, so need to be read differently from all other types)');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add(
      'When testing, use the Show/Edit INI button to see the results.  This will help you to understand');
    Memo_INI.Lines.Add(
      'how CryptINI works, and what it can do.  If you edit the INI, the app needs to restart to re-load it.');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add('CryptINI was designed to solve 2 issues:');
    Memo_INI.Lines.Add(
      '1. Making sure the ProgramInfo section is never altered, assuring you attribution stays secure.');
    Memo_INI.Lines.Add(
      'Once you have the MD5Hash of it, you can easily make an "authenticity checker" app using CryptINI');
    Memo_INI.Lines.Add(
      '2. Storing Passwords and Scores in an editable INI file which is tamper-proof to the casual hacker.');
    Memo_INI.Lines.Add(
      '(If numbers are written using WriteInteger, they are especially difficult to alter)');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add('In this app and ucryptini.pas is a DEFINE: {$DEFINE USE_DCPCRYPT}');
    Memo_INI.Lines.Add('This assumes you have the DCPCrypt runtime/designtime component installed.');
    Memo_INI.Lines.Add('If you haven''t then either install it or comment out the DEFINE and');
    Memo_INI.Lines.Add('remove it from Project Inspector. It is available via OnlinePackageManager');
    Memo_INI.Lines.Add('');
    Memo_INI.Lines.Add('Open ucryptini in a text editor to look at the commented code');
    Memo_INI.Lines.Add('- Enjoy!');
    ShowModal;
  end;
end;
{$IFDEF USE_DCPCRYPT}
procedure Tmainform.mnu_optionsDecryptINIFileClick(Sender: TObject);
begin
  If MessageDlg('Delete encrypted INI file?',mtConfirmation,[MBYES,MBNO],0,MBYes) = mrYes then
    INI.DecryptINI(TRUE)
  else
    INI.DecryptINI(FALSE);
  // Remember to reset the key phrase!
  INI.KeyPhrase := C_KEYPHRASE;

  // Update controls
  cmb_Sections.Clear;
  INI.ReadSections(cmb_Sections.Items);
  cmb_Sections.Refresh;
  cmb_Sections.ItemIndex := 0;
end;

procedure Tmainform.mnu_optionsEncryptINIFileClick(Sender: TObject);
begin
  If MessageDlg('Delete unencrypted INI file?',mtConfirmation,[MBYES,MBNO],0,MBYes) = mrYes then
    INI.EncryptINI(TRUE)
  else
    INI.EncryptINI(FALSE);
  Application.ProcessMessages;
  // Update controls
  cmb_Sections.Clear;
  cmb_Sections.ItemIndex := 0;
end;
{$ENDIF}

procedure Tmainform.mnu_optionsEncryptionKeyClick(Sender: TObject);
var
  s: string;
  l: longint;
begin
  keydialog.sKeyPhrase:=INI.KeyPhrase;
  KeyDialog.ShowModal;
  if KeyDialog.ModalResult = mrOk then
  begin
    s := KeyDialog.edt_key.Text;
    if TryStrToInt(s, l) then
      INI.Key := l
    else
      INI.Keyphrase := s;
    ShowMessage('Key changed successfully');
  end;
end;

procedure Tmainform.rg_EncryptionSelectionChanged(Sender: TObject);
begin
  if rg_Encryption.ItemIndex = 0 then
    INI.PlainTextMode := False
  else
    INI.PlainTextMode := True;
  if INI.PlainTextMode = True then
    rg_SectionHashing.ItemIndex := 1;
  cmd_Read.Enabled := False;
  cmd_Verify.Enabled := False;
end;

procedure Tmainform.rg_SectionHashingSelectionChanged(Sender: TObject);
begin
  if rg_SectionHashing.ItemIndex = 0 then
    INI.SectionHashing := True
  else
    INI.SectionHashing := False;
end;

procedure Tmainform.cmd_WriteClick(Sender: TObject);
var
  s: string;
begin
  // Best results when writing to TestSection
  if (edt_Section.Text <> 'TestSection') then
    if MessageDlg('Please confirm', 'Are you sure you want to write to ' +
      edt_Section.Text + '? (It should be "TestSection")', mtConfirmation, [mbYes,mbNo], 0, mbNo) =
      mrNo then
    begin
      edt_Section.Text := 'TestSection';
      ShowMessage('OK. Writing to default section "TestSection" instead');
    end;
  INI.SectionHashing:=FALSE;
  INI.WriteString(edt_Section.Text, edt_Ident.Text, edt_Value.Text);
  INI.WriteInteger(edt_Section.Text, 'Integer', StrToInt(edt_Integer.Text));
  // Write other types as a test
  INI.WriteBool(edt_Section.Text, 'Boolean', True);
  INI.WriteFloat(edt_Section.Text, 'Float', 3.142);
  INI.WriteDateTime(edt_Section.Text, 'Date', StrToDate('15/10/2016',
    'dd mm yyyy', '/'));
  INI.WriteInt64(edt_Section.Text, 'Int64', 1000);
  INI.SectionHashing:=TRUE;
  INI.MakeSectionHash(edt_Section.Text,TRUE);
  cmd_Read.Enabled := True;
  cmd_Verify.Enabled := True;
  s := 'Values written:' + LineEnding;
  s += 'WriteString: ' + edt_Value.Text + LineEnding;
  s += 'WriteFloat: 3.142' + LineEnding;
  s += 'WriteDateTime: 15/10/2016' + LineEnding;
  s += 'WriteInt64: 1000' + LineEnding;
  s += 'WriteInteger: ' + edt_Integer.Text + LineEnding;
  INI.ReadSections(cmb_Sections.Items);
  cmb_Sections.ItemIndex := Pred(cmb_Sections.Items.Count);
  ShowMessage(s);
end;

procedure Tmainform.cmd_EraseSectionClick(Sender: TObject);
begin
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to erase!');
    Exit;
  end;
  if edt_Section.Text = IDENT_SECTION then
    if MessageDlg('Please confirm', 'Are you sure you want to delete ' +
      IDENT_SECTION + '?', mtConfirmation, [mbCancel, mbYes], 0, mbCancel) =
      mrCancel then
      exit;
  INI.EraseSection(edt_Section.Text);
  ShowMessage('Section ' + edt_Section.Text + ' is no more.');
  INI.ReadSections(cmb_Sections.Items);
  cmb_Sections.ItemIndex := 0;
end;

procedure Tmainform.cmd_WriteSectionClick(Sender: TObject);
var
  iCount: integer;
  sTempSectionName: string;
  MyStringList: TStrings;
begin
  with InputSectionValuesForm do
  begin
    ShowModal;
    if ModalResult = mrCancel then
      Exit;
    sTempSectionName := sSectionName;
    if sTempSectionName = IDENT_SECTION then
      if MessageDlg('Please confirm', 'Are you sure you want to write to ' +
        IDENT_SECTION + '?', mtConfirmation, [mbYes, mbCancel], 0, mbCancel) =
        mrCancel then
        exit;
    edt_Section.Text := sSectionName;
    MyStringList := TStringList.Create;
    try
      MyStringList.Clear;
      MyStringList.BeginUpdate;
      for iCount := 0 to (NumberOfControls - 1) do
        MyStringList.Add(IdentEditArray[iCount].Text + '=' +
          ValueEditArray[iCount].Text);
      MyStringList.EndUpdate;
      INI.WriteSectionValues(sSectionName, MyStringList);
      INI.UpdateFile;
      ShowMessage('Section ' + sTempSectionName + ' written successfully');
    finally
      MyStringList.Free;
    end;
  end;
  INI.ReadSections(cmb_Sections.Items);
  cmb_Sections.ItemIndex := Pred(cmb_Sections.Items.Count);
end;

procedure Tmainform.edt_IntegerEditingDone(Sender: TObject);
var
  iTest: longint;
begin
  if not TryStrToInt(edt_Integer.Text, iTest) then
  begin
    ShowMessageFmt('%s is not an Integer.  Resetting to %s',
      [edt_Integer.Text, '12345']);
    edt_Integer.Text := '12345';
  end;
end;

procedure Tmainform.cmd_ReadClick(Sender: TObject);
var
  s: string;
begin
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to read!');
    Exit;
  end;
  // Dont read IDENT_SECTION
  if edt_Section.Text = IDENT_SECTION then
  begin
    cmd_ReadSectionValues.Click;
    Exit;
  end;
  if (edt_Section.Text <> 'TestSection') then
    if MessageDlg('Please confirm', 'Are you sure you want to read test values from ' +
      edt_Section.Text + '?', mtConfirmation, [mbCancel, mbYes], 0, mbCancel) =
      mrCancel then
    begin
      edt_Section.Text := 'TestSection';
      ShowMessage('OK. Reading default section "TestSection" instead');
    end;

  if INI.PlainTextMode then
    INI.MD5Hash := 'n/a';
  s := INI.ReadString(edt_Section.Text, edt_Ident.Text, 'unknown');
  ShowMessageFmt('Value of %s in %s is %s %s(MD5 hash: %s)',
    [edt_Ident.Text, edt_Section.Text, s, LineEnding, INI.MD5Hash]);
  if INI.ReadBool(edt_Section.Text, 'Boolean', False) = True then
    ShowMessageFmt('ReadBool is TRUE%s(MD5 hash: %s)', [LineEnding, INI.MD5Hash])
  else
    ShowMessageFmt('ReadBool is FALSE%s(MD5 hash: %s)', [LineEnding, INI.MD5Hash]);
  ShowMessageFmt('ReadFloat is %.3f%s(MD5 hash: %s)',
    [INI.ReadFloat(edt_Section.Text, 'Float', 0), LineEnding, INI.MD5Hash]);
  ShowMessageFmt('ReadDateTime is %s%s(MD5 hash: %s)',
    [DateToStr(INI.ReadDateTime(edt_Section.Text, 'Date', NOW)),
    LineEnding, INI.MD5Hash]);
  ShowMessageFmt('ReadInt64 is %d%s(MD5 hash: %s)',
    [INI.ReadInt64(edt_Section.Text, 'Int64', 0), LineEnding, INI.MD5Hash]);
  ShowMessageFmt('ReadInteger is %d%s(MD5 hash: %s)',
    [INI.ReadInteger(edt_Section.Text, 'Integer', 0), LineEnding, INI.MD5Hash]);
end;

procedure Tmainform.cmb_SectionsSelect(Sender: TObject);
begin
  edt_Section.Text := cmb_Sections.Items[cmb_Sections.ItemIndex];

end;

procedure Tmainform.cmd_DeleteValueClick(Sender: TObject);
begin
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to read!');
    Exit;
  end;
  if (edt_Section.Text <> 'TestSection') then
    if MessageDlg('Please confirm', 'Are you sure you want to delete test values from ' +
      edt_Section.Text + '?', mtConfirmation, [mbCancel, mbYes], 0, mbCancel) =
      mrCancel then
    begin
      edt_Section.Text := 'TestSection';
      ShowMessage('OK. Deleting values in default section "TestSection" instead');
    end;
  ShowMessage('Deleting values "' + edt_Ident.Text + '" and "Integer"');
  INI.DeleteKey(edt_Section.Text, edt_Ident.Text);
  INI.DeleteKey(edt_Section.Text, 'Integer');
  if INI.ValueExists(edt_Section.Text, edt_Ident.Text) then
    ShowMessage(edt_Ident.Text + ' not deleted!')
  else
    ShowMessage(edt_Ident.Text + ' deleted');
  if INI.ValueExists(edt_Section.Text, 'Integer') then
    ShowMessage('Integer not deleted!')
  else
    ShowMessage('Integer deleted');

end;

procedure Tmainform.cmd_ReadSectionValuesClick(Sender: TObject);
var
  MyStringList: TStrings;
  iCount: integer;
  TempPlainTextMode: boolean;
begin
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to read!');
    Exit;
  end;
  TempPlainTextMode := INI.PlainTextMode;
  if edt_Section.Text = IDENT_SECTION then
    INI.PlainTextMode := True;
  MyStringList := TStringList.Create;
  try
    INI.ReadSectionValues(edt_Section.Text, MyStringList);
    if MyStringList.Count > 0 then
      for iCount := 0 to Pred(MyStringList.Count) do
        ShowMessageFmt('Section name: %s%s(Value %d of %d): %s',
          [edt_Section.Text, LineEnding, iCount + 1, MyStringList.Count,
          MyStringList[iCount]])
    else
      ShowMessage('Nothing in this section!');
  finally
    MyStringList.Free;
  end;
  INI.PlainTextMode := TempPlainTextMode;
end;

procedure Tmainform.cmd_ShowINIClick(Sender: TObject);
Var s:String;
begin
  with ShowINIForm do
  begin
    MakeWriteable;
    Caption := 'Contents of ' + INI.Filename;
    Memo_INI.Lines.Clear;
    {$WARN  UNIT_DEPRECATED OFF}
    if LazFileUtils.FileExistsUTF8(INI.Filename) then
    begin
      Memo_INI.Lines.LoadFromFile(INI.Filename);
      sINIFilePath := INI.Filename;
      ShowModal;
      If bDirty then
      begin
        s:=INI.KeyPhrase;
        // Reload (with correct keyphrase)
        INI.Free;
        INI:=TCryptIniFile.Create(IniFilePath);
        INI.KeyPhrase:=s;
      end;
    end
    else
      ShowMessage('No INI file to show!');
  end;
end;

procedure Tmainform.cmd_ValueExistsClick(Sender: TObject);
begin
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to read!');
    Exit;
  end;
  // Dont read IDENT_SECTION
  if edt_Section.Text = IDENT_SECTION then
  begin
    ShowMessage('Switching Encryption mode off to read ' + IDENT_SECTION + 'section');
    rg_Encryption.ItemIndex := 1;
  end;
  if (edt_Section.Text <> 'TestSection') then
    if MessageDlg('Please confirm', 'Are you sure you want to test values from ' +
      edt_Section.Text + '?', mtConfirmation, [mbCancel, mbYes], 0, mbCancel) =
      mrCancel then
    begin
      edt_Section.Text := 'TestSection';
      ShowMessage('OK. Reading default section "TestSection" instead');
    end;

  if INI.ValueExists(edt_Section.Text, edt_Ident.Text) then
    ShowMessage('Key "' + edt_Ident.Text + '" exists')
  else
    ShowMessage('Key "' + edt_Ident.Text + '" is absent');
  if INI.ValueExists(edt_Section.Text, 'Integer') then
    ShowMessage('Key "Integer" exists')
  else
    ShowMessage('Key "Integer" is absent');
end;

procedure Tmainform.cmd_VerifyClick(Sender: TObject);
var
  TRUEFALSE: boolean;
begin
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to verify!');
    Exit;
  end;
  // Dont verify IDENT_SECTION
  if edt_Section.Text = IDENT_SECTION then
  begin
    cmd_VerifySectionValues.Click;
    Exit;
  end;
  if (edt_Section.Text <> 'TestSection') then
    if MessageDlg('Please confirm', 'Are you sure you want to verify test values from ' +
      edt_Section.Text + '?', mtConfirmation, [mbCancel, mbYes], 0, mbCancel) =
      mrCancel then
    begin
      edt_Section.Text := 'TestSection';
      ShowMessage('OK. Verifying default section "TestSection" instead');
    end;
  if INI.PlainTextMode = False then
  begin
    TRUEFALSE := True; // Assume success, look for failure
    // Test all the value types one-by-one
    TRUEFALSE := TRUEFALSE and INI.VerifyBool(edt_Section.Text, 'Boolean', True);
    if not INI.VerifyBool(edt_Section.Text, 'Boolean', True) then
      ShowMessage('Boolean failed to verify');
    TRUEFALSE := TRUEFALSE and INI.VerifyFloat(edt_Section.Text, 'Float', 3.142);
    if not INI.VerifyFloat(edt_Section.Text, 'Float', 3.142) then
      ShowMessage('Float failed to verify');
    TRUEFALSE := TRUEFALSE and INI.VerifyDateTime(edt_Section.Text,
      'Date', StrToDate('15/10/2016', 'dd mm yyyy', '/'));
    if not INI.VerifyDateTime(edt_Section.Text,
      'Date', StrToDate('15/10/2016', 'dd mm yyyy', '/')) then
      ShowMessage('Date failed to verify');
    TRUEFALSE := TRUEFALSE and INI.VerifyInt64(edt_Section.Text, 'Int64', 1000);
    if not INI.VerifyInt64(edt_Section.Text, 'Int64', 1000) then
      ShowMessage('Int64 failed to verify');
    TRUEFALSE := TRUEFALSE and INI.VerifyString(edt_Section.Text,
      edt_Ident.Text, edt_Value.Text);
    if not INI.VerifyString(edt_Section.Text,
      edt_Ident.Text, edt_Value.Text) then
      ShowMessage('String failed to verify');
    if TRUEFALSE = True then
      ShowMessage('Verify: String,Bool,Float,Date and Int64 types all verified OK')
    else
      ShowMessage('One or more types failed verification');
      // Test the Read/Write/Verify Integer stuff
    if INI.VerifyInteger(edt_Section.Text, 'Integer', StrToInt(edt_Integer.Text)) then
      ShowMessage('VerifyInteger: ' + edt_Integer.Text + ' verified OK')
    else
      ShowMessage('VerifyInteger: ' + edt_Integer.Text + ' failed verification');
  end
  else
  ShowMessage('Verification of regular values only works when PlainTextMode=FALSE');
  // Use the MD5 value from the INI file
  if INI.VerifyIdent('92abf0deecbb25c435bff507a396d92a') then
    ShowMessage('Ident ' + IDENT_SECTION + ' verified OK')
  else
    ShowMessage('Ident ' + IDENT_SECTION + ' failed verification');
end;

procedure Tmainform.cmd_VerifySectionValuesClick(Sender: TObject);
var
  s: string;
begin
  if edt_Section.Text = IDENT_SECTION then
  begin
    if INI.VerifyIdent('92abf0deecbb25c435bff507a396d92a') then
      ShowMessage('Ident ' + IDENT_SECTION + ' verified OK')
    else
      ShowMessage('Ident ' + IDENT_SECTION + ' failed verification');
    Exit;
  end;
  if not INI.SectionExists(edt_Section.Text) then
  begin
    ShowMessage(edt_Section.Text + ' is absent, so nothing to verify!');
    Exit;
  end;

  s := InputBox('Verify Section', 'Please enter your 32-character MD5Hash here',
    sStoredMD5Hash);
  if INI.VerifySectionHash(edt_Section.Text, s) then
  begin
    ShowMessage('Section is verified');
    sStoredMD5Hash := s;
  end
  else
    ShowMessage('MD5Hash value incorrect. Section failed verification');
end;

end.
