object TTTForm: TTTTForm
  Left = 0
  Top = 0
  Caption = 'Tic Tac Toe'
  ClientHeight = 424
  ClientWidth = 331
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = TTTFormCreate
  TextHeight = 15
  object InstructionsLabel: TLabel
    Left = 24
    Top = 8
    Width = 291
    Height = 23
    Caption = 'Select a Game Mode then click Start'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Segoe UI'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object PlayMethodGroup: TRadioGroup
    Left = 24
    Top = 248
    Width = 265
    Height = 105
    Caption = 'Game Mode'
    DefaultHeaderFont = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Segoe UI'
    Font.Style = []
    HeaderFont.Charset = DEFAULT_CHARSET
    HeaderFont.Color = clWindowText
    HeaderFont.Height = -17
    HeaderFont.Name = 'Segoe UI'
    HeaderFont.Style = [fsBold]
    Items.Strings = (
      'Computer goes first (I play O)'
      'I go first (I play X)'
      'Two players')
    ParentFont = False
    TabOrder = 1
    OnClick = PlayMethodGroupClick
  end
  object ClearButton: TButton
    Left = 134
    Top = 371
    Width = 75
    Height = 33
    Caption = '&Clear'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = ClearButtonClick
  end
  object StartButton: TButton
    Left = 24
    Top = 371
    Width = 75
    Height = 33
    Caption = '&Start'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -17
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 0
    OnClick = StartButtonClick
  end
end
