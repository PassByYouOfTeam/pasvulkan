(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                       Version see PasVulkan.Framework.pas                  *
 ******************************************************************************
 *                                zlib license                                *
 *============================================================================*
 *                                                                            *
 * Copyright (C) 2016-2017, Benjamin Rosseaux (benjamin@rosseaux.de)          *
 *                                                                            *
 * This software is provided 'as-is', without any express or implied          *
 * warranty. In no event will the authors be held liable for any damages      *
 * arising from the use of this software.                                     *
 *                                                                            *
 * Permission is granted to anyone to use this software for any purpose,      *
 * including commercial applications, and to alter it and redistribute it     *
 * freely, subject to the following restrictions:                             *
 *                                                                            *
 * 1. The origin of this software must not be misrepresented; you must not    *
 *    claim that you wrote the original software. If you use this software    *
 *    in a product, an acknowledgement in the product documentation would be  *
 *    appreciated but is not required.                                        *
 * 2. Altered source versions must be plainly marked as such, and must not be *
 *    misrepresented as being the original software.                          *
 * 3. This notice may not be removed or altered from any source distribution. *
 *                                                                            *
 ******************************************************************************
 *                  General guidelines for code contributors                  *
 *============================================================================*
 *                                                                            *
 * 1. Make sure you are legally allowed to make a contribution under the zlib *
 *    license.                                                                *
 * 2. The zlib license header goes at the top of each source file, with       *
 *    appropriate copyright notice.                                           *
 * 3. This PasVulkan wrapper may be used only with the PasVulkan-own Vulkan   *
 *    Pascal header.                                                          *
 * 4. After a pull request, check the status of your pull request on          *
      http://github.com/BeRo1985/pasvulkan                                    *
 * 5. Write code which's compatible with Delphi >= 2009 and FreePascal >=     *
 *    3.1.1                                                                   *
 * 6. Don't use Delphi-only, FreePascal-only or Lazarus-only libraries/units, *
 *    but if needed, make it out-ifdef-able.                                  *
 * 7. No use of third-party libraries/units as possible, but if needed, make  *
 *    it out-ifdef-able.                                                      *
 * 8. Try to use const when possible.                                         *
 * 9. Make sure to comment out writeln, used while debugging.                 *
 * 10. Make sure the code compiles on 32-bit and 64-bit platforms (x86-32,    *
 *     x86-64, ARM, ARM64, etc.).                                             *
 * 11. Make sure the code runs on all platforms with Vulkan support           *
 *                                                                            *
 ******************************************************************************)
unit PasVulkan.GUI;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}
{$m+}

interface

uses SysUtils,
     Classes,
     Math,
     Generics.Collections,
     PasMP,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Utils,
     PasVulkan.Collections,
     PasVulkan.Math,
     PasVulkan.Framework,
     PasVulkan.Application,
     PasVulkan.Streams,
     PasVulkan.Sprites,
     PasVulkan.Canvas,
     PasVulkan.TrueTypeFont,
     PasVulkan.Font;

type TpvGUIObject=class;

     TpvGUIWidget=class;

     TpvGUIInstance=class;

     TpvGUIWindow=class;

     TpvGUILabel=class;

     TpvGUIButton=class;

     EpvGUIWidget=class(Exception);

     TpvGUIOnEvent=procedure(const aSender:TpvGUIObject) of object;

     TpvGUIObjectList=class(TObjectList<TpvGUIObject>)
      protected
       procedure Notify({$ifdef fpc}constref{$else}const{$endif} Value:TpvGUIObject;Action:TCollectionNotification); override;
      public
     end;

     TpvGUIObject=class(TpvReferenceCountedObject)
      private
       fInstance:TpvGUIInstance;
       fParent:TpvGUIObject;
       fChildren:TpvGUIObjectList;
       fID:TpvUTF8String;
       fTag:TpvPtrInt;
       fReferenceCounter:TpvInt32;
      public
       constructor Create(const aParent:TpvGUIObject); reintroduce; virtual;
       destructor Destroy; override;
       procedure AfterConstruction; override;
       procedure BeforeDestruction; override;
      published
       property Instance:TpvGUIInstance read fInstance;
       property Parent:TpvGUIObject read fParent write fParent;
       property Children:TpvGUIObjectList read fChildren;
       property ID:TpvUTF8String read fID write fID;
       property Tag:TpvPtrInt read fTag write fTag;
       property ReferenceCounter:TpvInt32 read fReferenceCounter write fReferenceCounter;
     end;

     PpvGUILayoutAlignment=^TpvGUILayoutAlignment;
     TpvGUILayoutAlignment=
      (
       pvglaLeading,
       pvglaMiddle,
       pvglaTailing,
       pvglaFill
      );

     PpvGUILayoutOrientation=^TpvGUILayoutOrientation;
     TpvGUILayoutOrientation=
      (
       pvgloHorizontal,
       pvgloVertical
      );

     TpvGUILayout=class(TpvGUIObject)
      protected
       function GetPreferredSize(const aWidget:TpvGUIWidget):TpvVector2; virtual;
       procedure PerformLayout(const aWidget:TpvGUIWidget); virtual;
      public
     end;

     TpvGUIBoxLayout=class(TpvGUILayout)
      private
       fAlignment:TpvGUILayoutAlignment;
       fOrientation:TpvGUILayoutOrientation;
       fMargin:TpvFloat;
       fSpacing:TpvFloat;
      protected
       function GetPreferredSize(const aWidget:TpvGUIWidget):TpvVector2; override;
       procedure PerformLayout(const aWidget:TpvGUIWidget); override;
      public
       constructor Create(const aParent:TpvGUIObject;
                          const aAlignment:TpvGUILayoutAlignment=pvglaMiddle;
                          const aOrientation:TpvGUILayoutOrientation=pvgloHorizontal;
                          const aMargin:TpvFloat=0.0;
                          const aSpacing:TpvFloat=0.0); reintroduce; virtual;
       destructor Destroy; override;
      published
       property Alignment:TpvGUILayoutAlignment read fAlignment write fAlignment;
       property Orientation:TpvGUILayoutOrientation read fOrientation write fOrientation;
       property Margin:TpvFloat read fMargin write fMargin;
       property Spacing:TpvFloat read fSpacing write fSpacing;
     end;

     TpvGUISkin=class(TpvGUIObject)
      private
      protected
       fFontSize:TpvFloat;
       fUnfocusedWindowHeaderFontSize:TpvFloat;
       fFocusedWindowHeaderFontSize:tpvFloat;
       fFontSpriteAtlas:TpvSpriteAtlas;
       fSansFont:TpvFont;
       fMonoFont:TpvFont;
       fWindowHeaderHeight:TpvFloat;
       fWindowResizeGripSize:TpvFloat;
       fWindowMinimumWidth:TpvFloat;
       fWindowMinimumHeight:TpvFloat;
      public
       constructor Create(const aParent:TpvGUIObject); override;
       destructor Destroy; override;
       procedure Setup; virtual;
       procedure DrawMouse(const aCanvas:TpvCanvas;const aInstance:TpvGUIInstance); virtual;
       procedure DrawWindow(const aCanvas:TpvCanvas;const aWindow:TpvGUIWindow); virtual;
       procedure DrawLabel(const aCanvas:TpvCanvas;const aLabel:TpvGUILabel); virtual;
       procedure DrawButton(const aCanvas:TpvCanvas;const aButton:TpvGUIButton); virtual;
      published
       property FontSize:TpvFloat read fFontSize write fFontSize;
       property UnfocusedWindowHeaderFontSize:TpvFloat read fUnfocusedWindowHeaderFontSize write fUnfocusedWindowHeaderFontSize;
       property FocusedWindowHeaderFontSize:TpvFloat read fFocusedWindowHeaderFontSize write fFocusedWindowHeaderFontSize;
       property FontSpriteAtlas:TpvSpriteAtlas read fFontSpriteAtlas;
       property WindowHeaderHeight:TpvFloat read fWindowHeaderHeight write fWindowHeaderHeight;
       property WindowResizeGripSize:TpvFloat read fWindowResizeGripSize write fWindowResizeGripSize;
       property WindowMinimumWidth:TpvFloat read fWindowMinimumWidth write fWindowMinimumWidth;
       property WindowMinimumHeight:TpvFloat read fWindowMinimumHeight write fWindowMinimumHeight;
     end;

     TpvGUIDefaultVectorBasedSkin=class(TpvGUISkin)
      private
      protected
       fUnfocusedWindowHeaderFontShadow:boolean;
       fFocusedWindowHeaderFontShadow:boolean;
       fUnfocusedWindowHeaderFontShadowOffset:TpvVector2;
       fFocusedWindowHeaderFontShadowOffset:TpvVector2;
       fUnfocusedWindowHeaderFontShadowColor:TpvVector4;
       fFocusedWindowHeaderFontShadowColor:TpvVector4;
       fUnfocusedWindowHeaderFontColor:TpvVector4;
       fFocusedWindowHeaderFontColor:TpvVector4;
       fLabelFontColor:TpvVector4;
       fWindowShadowWidth:TpvFloat;
       fWindowShadowHeight:TpvFloat;
      public
       constructor Create(const aParent:TpvGUIObject); override;
       destructor Destroy; override;
       procedure Setup; override;
       procedure DrawMouse(const aCanvas:TpvCanvas;const aInstance:TpvGUIInstance); override;
       procedure DrawWindow(const aCanvas:TpvCanvas;const aWindow:TpvGUIWindow); override;
       procedure DrawLabel(const aCanvas:TpvCanvas;const aLabel:TpvGUILabel); override;
       procedure DrawButton(const aCanvas:TpvCanvas;const aButton:TpvGUIButton); override;
      public
       property UnfocusedWindowHeaderFontShadowOffset:TpvVector2 read fUnfocusedWindowHeaderFontShadowOffset write fUnfocusedWindowHeaderFontShadowOffset;
       property FocusedWindowHeaderFontShadowOffset:TpvVector2 read fFocusedWindowHeaderFontShadowOffset write fFocusedWindowHeaderFontShadowOffset;
       property UnfocusedWindowHeaderFontShadowColor:TpvVector4 read fUnfocusedWindowHeaderFontShadowColor write fUnfocusedWindowHeaderFontShadowColor;
       property FocusedWindowHeaderFontShadowColor:TpvVector4 read fFocusedWindowHeaderFontShadowColor write fFocusedWindowHeaderFontShadowColor;
       property UnfocusedWindowHeaderFontColor:TpvVector4 read fUnfocusedWindowHeaderFontColor write fUnfocusedWindowHeaderFontColor;
       property FocusedWindowHeaderFontColor:TpvVector4 read fFocusedWindowHeaderFontColor write fFocusedWindowHeaderFontColor;
      published
       property UnfocusedWindowHeaderFontShadow:boolean read fUnfocusedWindowHeaderFontShadow write fUnfocusedWindowHeaderFontShadow;
       property FocusedWindowHeaderFontShadow:boolean read fFocusedWindowHeaderFontShadow write fFocusedWindowHeaderFontShadow;
       property WindowShadowWidth:TpvFloat read fWindowShadowWidth write fWindowShadowWidth;
       property WindowShadowHeight:TpvFloat read fWindowShadowHeight write fWindowShadowHeight;
     end;

     PpvGUICursor=^TpvGUICursor;
     TpvGUICursor=
      (
       pvgcNone,
       pvgcArrow,
       pvgcBeam,
       pvgcBusy,
       pvgcCross,
       pvgcEW,
       pvgcHelp,
       pvgcLink,
       pvgcMove,
       pvgcNESW,
       pvgcNS,
       pvgcNWSE,
       pvgcPen,
       pvgcUnavailable,
       pvgcUp
      );

     TpvGUIWidgetEnumerator=class(TEnumerator<TpvGUIWidget>)
      private
       fWidget:TpvGUIWidget;
       fIndex:TpvSizeInt;
      protected
       function DoMoveNext:boolean; override;
       function DoGetCurrent:TpvGUIWidget; override;
      public
       constructor Create(const aWidget:TpvGUIWidget); reintroduce;
     end;

     PpvGUIWidgetFlag=^TpvGUIWidgetFlag;
     TpvGUIWidgetFlag=
      (
       pvgwfEnabled,
       pvgwfVisible,
       pvgwfFocused,
       pvgwfPointerFocused
      );

     PpvGUIWidgetFlags=^TpvGUIWidgetFlags;
     TpvGUIWidgetFlags=set of TpvGUIWidgetFlag;

     TpvGUIWidget=class(TpvGUIObject)
      public
       const DefaultFlags=[pvgwfEnabled,
                           pvgwfVisible];
      private
      protected
       fCanvas:TpvCanvas;
       fLayout:TpvGUILayout;
       fSkin:TpvGUISkin;
       fCursor:TpvGUICursor;
       fPosition:TpvVector2;
       fSize:TpvVector2;
       fFixedSize:TpvVector2;
       fPositionProperty:TpvVector2Property;
       fSizeProperty:TpvVector2Property;
       fFixedSizeProperty:TpvVector2Property;
       fWidgetFlags:TpvGUIWidgetFlags;
       fHint:TpvUTF8String;
       fFontSize:TpvFloat;
       function GetEnabled:boolean; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetEnabled(const aEnabled:boolean); {$ifdef CAN_INLINE}inline;{$endif}
       function GetVisible:boolean; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetVisible(const aVisible:boolean); {$ifdef CAN_INLINE}inline;{$endif}
       function GetFocused:boolean; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetFocused(const aFocused:boolean); {$ifdef CAN_INLINE}inline;{$endif}
       function GetPointerFocused:boolean; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetPointerFocused(const aPointerFocused:boolean); {$ifdef CAN_INLINE}inline;{$endif}
       function GetLeft:TpvFloat; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetLeft(const aLeft:TpvFloat); {$ifdef CAN_INLINE}inline;{$endif}
       function GetTop:TpvFloat; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetTop(const aTop:TpvFloat); {$ifdef CAN_INLINE}inline;{$endif}
       function GetWidth:TpvFloat; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetWidth(const aWidth:TpvFloat); {$ifdef CAN_INLINE}inline;{$endif}
       function GetHeight:TpvFloat; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetHeight(const aHeight:TpvFloat); {$ifdef CAN_INLINE}inline;{$endif}
       function GetFixedWidth:TpvFloat; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetFixedWidth(const aFixedWidth:TpvFloat); {$ifdef CAN_INLINE}inline;{$endif}
       function GetFixedHeight:TpvFloat; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetFixedHeight(const aFixedHeight:TpvFloat); {$ifdef CAN_INLINE}inline;{$endif}
       function GetAbsolutePosition:TpvVector2; {$ifdef CAN_INLINE}inline;{$endif}
       function GetRecursiveVisible:boolean; {$ifdef CAN_INLINE}inline;{$endif}
       function GetWindow:TpvGUIWindow;
       procedure SetCanvas(const aCanvas:TpvCanvas); virtual;
       function GetSkin:TpvGUISkin; virtual;
       procedure SetSkin(const aSkin:TpvGUISkin); virtual;
       function GetPreferredSize:TpvVector2; virtual;
       function GetFontSize:TpvFloat; virtual;
      public
       constructor Create(const aParent:TpvGUIObject); override;
       destructor Destroy; override;
       procedure AfterConstruction; override;
       procedure BeforeDestruction; override;
       function GetEnumerator:TpvGUIWidgetEnumerator;
       function Contains(const aPosition:TpvVector2):boolean; {$ifdef CAN_INLINE}inline;{$endif}
       function FindWidget(const aPosition:TpvVector2):TpvGUIWidget;
       procedure PerformLayout; virtual;
       procedure RequestFocus; virtual;
       function Enter:boolean; virtual;
       function Leave:boolean; virtual;
       function PointerEnter:boolean; virtual;
       function PointerLeave:boolean; virtual;
       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; virtual;
       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; virtual;
       function Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean; virtual;
       procedure AfterCreateSwapChain; virtual;
       procedure BeforeDestroySwapChain; virtual;
       procedure Update; virtual;
       procedure Draw; virtual;
      public
       property AbsolutePosition:TpvVector2 read GetAbsolutePosition;
       property PreferredSize:TpvVector2 read GetPreferredSize;
      published
       property Window:TpvGUIWindow read GetWindow;
       property Canvas:TpvCanvas read fCanvas write SetCanvas;
       property Layout:TpvGUILayout read fLayout write fLayout;
       property Skin:TpvGUISkin read GetSkin write SetSkin;
       property Cursor:TpvGUICursor read fCursor write fCursor;
       property Position:TpvVector2Property read fPositionProperty;
       property Size:TpvVector2Property read fSizeProperty;
       property FixedSize:TpvVector2Property read fFixedSizeProperty;
       property WidgetFlags:TpvGUIWidgetFlags read fWidgetFlags write fWidgetFlags;
       property Enabled:boolean read GetEnabled write SetEnabled;
       property Visible:boolean read GetVisible write SetVisible;
       property RecursiveVisible:boolean read GetRecursiveVisible;
       property Focused:boolean read GetFocused write SetFocused;
       property PointerFocused:boolean read GetPointerFocused write SetPointerFocused;
       property Left:TpvFloat read GetLeft write SetLeft;
       property Top:TpvFloat read GetTop write SetTop;
       property Width:TpvFloat read GetWidth write SetWidth;
       property Height:TpvFloat read GetHeight write SetHeight;
       property FixedWidth:TpvFloat read GetFixedWidth write SetFixedWidth;
       property FixedHeight:TpvFloat read GetFixedHeight write SetFixedHeight;
       property Hint:TpvUTF8String read fHint write fHint;
       property FontSize:TpvFloat read GetFontSize write fFontSize;
     end;

     TpvGUIInstanceBufferReferenceCountedObjects=array of TpvReferenceCountedObject;

     PpvGUIInstanceBuffer=^TpvGUIInstanceBuffer;
     TpvGUIInstanceBuffer=record
      ReferenceCountedObjects:TpvGUIInstanceBufferReferenceCountedObjects;
      CountReferenceCountedObjects:TpvInt32;
     end;

     TpvGUIInstanceBuffers=array of TpvGUIInstanceBuffer;

     TpvGUIInstance=class(TpvGUIWidget)
      private
       fVulkanDevice:TpvVulkanDevice;
       fStandardSkin:TpvGUISkin;
       fDrawWidgetBounds:boolean;
       fBuffers:TpvGUIInstanceBuffers;
       fCountBuffers:TpvInt32;
       fUpdateBufferIndex:TpvInt32;
       fDrawBufferIndex:TpvInt32;
       fDeltaTime:TpvDouble;
       fTime:TpvDouble;
       fLastFocusPath:TpvGUIObjectList;
       fCurrentFocusPath:TpvGUIObjectList;
       fDragWidget:TpvGUIWidget;
       fWindow:TpvGUIWindow;
       fMousePosition:TpvVector2;
       fVisibleCursor:TpvGUICursor;
       procedure SetCountBuffers(const aCountBuffers:TpvInt32);
       procedure SetUpdateBufferIndex(const aUpdateBufferIndex:TpvInt32);
       procedure SetDrawBufferIndex(const aDrawBufferIndex:TpvInt32);
       procedure DisposeWindow(const aWindow:TpvGUIWindow);
       procedure CenterWindow(const aWindow:TpvGUIWindow);
       procedure MoveWindowToFront(const aWindow:TpvGUIWindow);
      public
       constructor Create(const aVulkanDevice:TpvVulkanDevice); reintroduce;
       destructor Destroy; override;
       procedure AfterConstruction; override;
       procedure BeforeDestruction; override;
       procedure ClearReferenceCountedObjectList;
       procedure AddReferenceCountedObjectForNextDraw(const aObject:TpvReferenceCountedObject);
       procedure UpdateFocus(const aWidget:TpvGUIWidget);
       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; override;
       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; override;
       function Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean; override;
       procedure Update; override;
       procedure Draw; override;
      public
       property MousePosition:TpvVector2 read fMousePosition write fMousePosition;
      published
       property VulkanDevice:TpvVulkanDevice read fVulkanDevice;
       property StandardSkin:TpvGUISkin read fStandardSkin;
       property DrawWidgetBounds:boolean read fDrawWidgetBounds write fDrawWidgetBounds;
       property CountBuffers:TpvInt32 read fCountBuffers write SetCountBuffers;
       property UpdateBufferIndex:TpvInt32 read fUpdateBufferIndex write fUpdateBufferIndex;
       property DrawBufferIndex:TpvInt32 read fDrawBufferIndex write fDrawBufferIndex;
       property DeltaTime:TpvDouble read fDeltaTime write fDeltaTime;
     end;

     PpvGUIWindowMouseAction=^TpvGUIWindowMouseAction;
     TpvGUIWindowMouseAction=
      (
       pvgwmaNone,
       pvgwmaMove,
       pvgwmaSizeNW,
       pvgwmaSizeNE,
       pvgwmaSizeSW,
       pvgwmaSizeSE,
       pvgwmaSizeN,
       pvgwmaSizeS,
       pvgwmaSizeW,
       pvgwmaSizeE
      );

     PpvGUIWindowFlag=^TpvGUIWindowFlag;
     TpvGUIWindowFlag=
      (
       pvgwfModal,
       pvgwfHeader,
       pvgwfMovable,
       pvgwfResizableNW,
       pvgwfResizableNE,
       pvgwfResizableSW,
       pvgwfResizableSE,
       pvgwfResizableN,
       pvgwfResizableS,
       pvgwfResizableW,
       pvgwfResizableE
      );

     PpvGUIWindowFlags=^TpvGUIWindowFlags;
     TpvGUIWindowFlags=set of TpvGUIWindowFlag;

     TpvGUIWindow=class(TpvGUIWidget)
      public
       const DefaultFlags=[pvgwfHeader,
                           pvgwfMovable,
                           pvgwfResizableNW,
                           pvgwfResizableNE,
                           pvgwfResizableSW,
                           pvgwfResizableSE,
                           pvgwfResizableN,
                           pvgwfResizableS,
                           pvgwfResizableW,
                           pvgwfResizableE];
      private
      protected
       fTitle:TpvUTF8String;
       fMouseAction:TpvGUIWindowMouseAction;
       fWindowFlags:TpvGUIWindowFlags;
       fButtonPanel:TpvGUIWidget;
       function GetModal:boolean; {$ifdef CAN_INLINE}inline;{$endif}
       procedure SetModal(const aModal:boolean); {$ifdef CAN_INLINE}inline;{$endif}
       function GetButtonPanel:TpvGUIWidget;
       function GetPreferredSize:TpvVector2; override;
       procedure RefreshRelativePlacement; virtual;
      public
       constructor Create(const aParent:TpvGUIObject); override;
       destructor Destroy; override;
       procedure AfterConstruction; override;
       procedure BeforeDestruction; override;
       procedure DisposeWindow;
       procedure Center;
       procedure PerformLayout; override;
       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; override;
       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; override;
       function Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean; override;
       procedure Update; override;
       procedure Draw; override;
      published
       property Title:TpvUTF8String read fTitle write fTitle;
       property WindowFlags:TpvGUIWindowFlags read fWindowFlags write fWindowFlags;
       property Modal:boolean read GetModal write SetModal;
       property ButtonPanel:TpvGUIWidget read GetButtonPanel;
     end;

     TpvGUILabel=class(TpvGUIWidget)
      private
       fCaption:TpvUTF8String;
      protected
       function GetPreferredSize:TpvVector2; override;
      public
       constructor Create(const aParent:TpvGUIObject); override;
       destructor Destroy; override;
       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; override;
       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; override;
       function Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean; override;
       procedure Update; override;
       procedure Draw; override;
      published
       property Caption:TpvUTF8String read fCaption write fCaption;
     end;

     PpvGUIButtonFlag=^TpvGUIButtonFlag;
     TpvGUIButtonFlag=
      (
       pvgbfNormalButton,
       pvgbfRadioButton,
       pvgbfToggleButton,
       pvgbfPopupButton,
       pvgbfDown
      );

     PpvGUIButtonFlags=^TpvGUIButtonFlags;
     TpvGUIButtonFlags=set of TpvGUIButtonFlag;

     TpvGUIButton=class(TpvGUIWidget)
      private
       fButtonFlags:TpvGUIButtonFlags;
       fCaption:TpvUTF8String;
       fOnClick:TpvGUIOnEvent;
      protected
       function GetDown:boolean; inline;
       procedure SetDown(const aDown:boolean); inline;
       function GetPreferredSize:TpvVector2; override;
      public
       constructor Create(const aParent:TpvGUIObject); override;
       destructor Destroy; override;
       function KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean; override;
       function PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean; override;
       function Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean; override;
       procedure Update; override;
       procedure Draw; override;
      published
       property ButtonFlags:TpvGUIButtonFlags read fButtonFlags write fButtonFlags;
       property Down:boolean read GetDown write SetDown;
       property Caption:TpvUTF8String read fCaption write fCaption;
       property OnClick:TpvGUIOnEvent read fOnClick write fOnClick;
     end;

     TpvGUIRadioButton=class(TpvGUIButton)
      public
       constructor Create(const aParent:TpvGUIObject); override;
     end;

     TpvGUIToggleButton=class(TpvGUIButton)
      public
       constructor Create(const aParent:TpvGUIObject); override;
     end;

     TpvGUIPopupButton=class(TpvGUIButton)
      public
       constructor Create(const aParent:TpvGUIObject); override;
     end;

     TpvGUIToolButton=class(TpvGUIButton)
      public
       constructor Create(const aParent:TpvGUIObject); override;
     end;

implementation

uses PasVulkan.Assets,
     PasVulkan.VectorPath,
     PasVulkan.Image.PNG;

const GUI_ELEMENT_WINDOW_HEADER=1;
      GUI_ELEMENT_WINDOW_FILL=2;
      GUI_ELEMENT_WINDOW_DROPSHADOW=3;
      GUI_ELEMENT_BUTTON_UNFOCUSED=4;
      GUI_ELEMENT_BUTTON_FOCUSED=5;
      GUI_ELEMENT_BUTTON_PUSHED=6;
      GUI_ELEMENT_BUTTON_DISABLED=7;
      GUI_ELEMENT_BUTTON_HOVERED=8;
      GUI_ELEMENT_MOUSE_CURSOR_ARROW=64;
      GUI_ELEMENT_MOUSE_CURSOR_BEAM=65;
      GUI_ELEMENT_MOUSE_CURSOR_BUSY=66;
      GUI_ELEMENT_MOUSE_CURSOR_CROSS=67;
      GUI_ELEMENT_MOUSE_CURSOR_EW=68;
      GUI_ELEMENT_MOUSE_CURSOR_HELP=69;
      GUI_ELEMENT_MOUSE_CURSOR_LINK=70;
      GUI_ELEMENT_MOUSE_CURSOR_MOVE=71;
      GUI_ELEMENT_MOUSE_CURSOR_NESW=72;
      GUI_ELEMENT_MOUSE_CURSOR_NS=73;
      GUI_ELEMENT_MOUSE_CURSOR_NWSE=74;
      GUI_ELEMENT_MOUSE_CURSOR_PEN=75;
      GUI_ELEMENT_MOUSE_CURSOR_UNAVAILABLE=76;
      GUI_ELEMENT_MOUSE_CURSOR_UP=77;

procedure TpvGUIObjectList.Notify({$ifdef fpc}constref{$else}const{$endif} Value:TpvGUIObject;Action:TCollectionNotification);
begin
 if assigned(Value) then begin
  case Action of
   cnAdded:begin
    Value.IncRef;
   end;
   cnRemoved:begin
    Value.DecRef;
   end;
   cnExtracted:begin
   end;
  end;
 end else begin
  inherited Notify(Value,Action);
 end;
end;

constructor TpvGUIObject.Create(const aParent:TpvGUIObject);
begin

 inherited Create;

 if assigned(aParent) then begin
  fInstance:=aParent.fInstance;
 end else if self is TpvGUIInstance then begin
  fInstance:=TpvGUIInstance(self);
 end else begin
  fInstance:=nil;
 end;

 fParent:=aParent;

 fChildren:=TpvGUIObjectList.Create(false);

 fID:='';

 fTag:=0;

 fReferenceCounter:=0;

end;

destructor TpvGUIObject.Destroy;
begin
 FreeAndNil(fChildren);
 inherited Destroy;
end;

procedure TpvGUIObject.AfterConstruction;
begin
 inherited AfterConstruction;
 if assigned(fParent) then begin
  fParent.fChildren.Add(self);
 end;
end;

procedure TpvGUIObject.BeforeDestruction;
begin
 if assigned(fParent) and assigned(fParent.fChildren) then begin
  fParent.fChildren.Extract(self);
 end;
 inherited BeforeDestruction;
end;

function TpvGUILayout.GetPreferredSize(const aWidget:TpvGUIWidget):TpvVector2;
begin
 result:=aWidget.fSize;
end;

procedure TpvGUILayout.PerformLayout(const aWidget:TpvGUIWidget);
begin

end;

constructor TpvGUIBoxLayout.Create(const aParent:TpvGUIObject;
                                   const aAlignment:TpvGUILayoutAlignment=pvglaMiddle;
                                   const aOrientation:TpvGUILayoutOrientation=pvgloHorizontal;
                                   const aMargin:TpvFloat=0.0;
                                   const aSpacing:TpvFloat=0.0);
begin
 inherited Create(aParent);
 fAlignment:=aAlignment;
 fOrientation:=aOrientation;
 fMargin:=aMargin;
 fSpacing:=aSpacing;
end;

destructor TpvGUIBoxLayout.Destroy;
begin
 inherited Destroy;
end;

function TpvGUIBoxLayout.GetPreferredSize(const aWidget:TpvGUIWidget):TpvVector2;
var Axis0,Axis1,ChildIndex:TpvInt32;
    YOffset:TpvFloat;
    Size,ChildPreferredSize,ChildFixedSize,ChildTargetSize:TpvVector2;
    First:boolean;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 Size:=TpvVector2.Create(fMargin*2.0,fMargin*2.0);
 YOffset:=0;
 if (aWidget is TpvGUIWindow) and
    (pvgwfHeader in (aWidget as TpvGUIWindow).fWindowFlags) then begin
  case fOrientation of
   pvgloHorizontal:begin
    YOffset:=aWidget.Skin.WindowHeaderHeight;
   end;
   pvgloVertical:begin
    Size.y:=Size.y+(aWidget.Skin.WindowHeaderHeight-(fMargin*0.5));
   end;
  end;
 end;
 case fOrientation of
  pvgloHorizontal:begin
   Axis0:=0;
   Axis1:=1;
  end;
  else begin
   Axis0:=1;
   Axis1:=0;
  end;
 end;
 First:=true;
 for ChildIndex:=0 to aWidget.fChildren.Count-1 do begin
  Child:=aWidget.fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   if ChildWidget.Visible then begin
    if not First then begin
     Size[Axis0]:=Size[Axis0]+fSpacing;
    end;
    ChildPreferredSize:=ChildWidget.PreferredSize;
    ChildFixedSize:=ChildWidget.fFixedSize;
    if ChildFixedSize.x>0.0 then begin
     ChildTargetSize.x:=ChildFixedSize.x;
    end else begin
     ChildTargetSize.x:=ChildPreferredSize.x;
    end;
    if ChildFixedSize.y>0.0 then begin
     ChildTargetSize.y:=ChildFixedSize.y;
    end else begin
     ChildTargetSize.y:=ChildPreferredSize.y;
    end;
    Size[Axis0]:=Size[Axis0]+ChildTargetSize[Axis0];
    Size[Axis1]:=Max(Size[Axis1],ChildTargetSize[Axis1]+(fMargin*2.0));
    First:=false;
   end;
  end;
 end;
 result:=Size+TpvVector2.Create(0.0,YOffset);
end;

procedure TpvGUIBoxLayout.PerformLayout(const aWidget:TpvGUIWidget);
var Axis0,Axis1,ChildIndex:TpvInt32;
    Offset,YOffset:TpvFloat;
    FixedSize,ContainerSize,ChildPreferredSize,ChildFixedSize,ChildTargetSize,
    Position:TpvVector2;
    First:boolean;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 FixedSize:=aWidget.fFixedSize;
 if FixedSize.x>0.0 then begin
  ContainerSize.x:=FixedSize.x;
 end else begin
  ContainerSize.x:=aWidget.Width;
 end;
 if FixedSize.y>0.0 then begin
  ContainerSize.y:=FixedSize.y;
 end else begin
  ContainerSize.y:=aWidget.Height;
 end;
 case fOrientation of
  pvgloHorizontal:begin
   Axis0:=0;
   Axis1:=1;
  end;
  else begin
   Axis0:=1;
   Axis1:=0;
  end;
 end;
 Offset:=fMargin;
 YOffset:=0;
 if (aWidget is TpvGUIWindow) and
    (pvgwfHeader in (aWidget as TpvGUIWindow).fWindowFlags) then begin
  case fOrientation of
   pvgloHorizontal:begin
    YOffset:=aWidget.Skin.WindowHeaderHeight;
    ContainerSize.y:=ContainerSize.y-YOffset;
   end;
   pvgloVertical:begin
    Offset:=Offset+(aWidget.Skin.WindowHeaderHeight-(fMargin*0.5));
   end;
  end;
 end;
 First:=true;
 for ChildIndex:=0 to aWidget.fChildren.Count-1 do begin
  Child:=aWidget.fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   if ChildWidget.Visible then begin
    if not First then begin
     Offset:=Offset+fSpacing;
    end;
    ChildPreferredSize:=ChildWidget.PreferredSize;
    ChildFixedSize:=ChildWidget.fFixedSize;
    if ChildFixedSize.x>0.0 then begin
     ChildTargetSize.x:=ChildFixedSize.x;
    end else begin
     ChildTargetSize.x:=ChildPreferredSize.x;
    end;
    if ChildFixedSize.y>0.0 then begin
     ChildTargetSize.y:=ChildFixedSize.y;
    end else begin
     ChildTargetSize.y:=ChildPreferredSize.y;
    end;
    Position:=TpvVector2.Create(0,YOffset);
    Position[Axis0]:=Offset;
    case fAlignment of
     pvglaLeading:begin
      Position[Axis1]:=Position[Axis1]+fMargin;
     end;
     pvglaMiddle:begin
      Position[Axis1]:=Position[Axis1]+((ContainerSize[Axis1]-ChildTargetSize[Axis1])*0.5);
     end;
     pvglaTailing:begin
      Position[Axis1]:=Position[Axis1]+((ContainerSize[Axis1]-ChildTargetSize[Axis1])-(fMargin*2.0));
     end;
     else {pvglaFill:}begin
      Position[Axis1]:=Position[Axis1]+fMargin;
      if ChildFixedSize[Axis1]>0.0 then begin
       ChildTargetSize[Axis1]:=ChildFixedSize[Axis1];
      end else begin
       ChildTargetSize[Axis1]:=ContainerSize[Axis1]-(fMargin*2.0);
      end;
     end;
    end;
    ChildWidget.fPosition:=Position;
    ChildWidget.fSize:=ChildTargetSize;
    ChildWidget.PerformLayout;
    Offset:=Offset+ChildTargetSize[Axis0];
    First:=false;
   end;
  end;
 end;
end;

constructor TpvGUISkin.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fFontSpriteAtlas:=nil;
 fSansFont:=nil;
 fMonoFont:=nil;
 Setup;
end;

destructor TpvGUISkin.Destroy;
begin
 FreeAndNil(fSansFont);
 FreeAndNil(fMonoFont);
 FreeAndNil(fFontSpriteAtlas);
 inherited Destroy;
end;

procedure TpvGUISkin.Setup;
begin

end;

procedure TpvGUISkin.DrawMouse(const aCanvas:TpvCanvas;const aInstance:TpvGUIInstance);
begin
end;

procedure TpvGUISkin.DrawWindow(const aCanvas:TpvCanvas;const aWindow:TpvGUIWindow);
begin
end;

procedure TpvGUISkin.DrawLabel(const aCanvas:TpvCanvas;const aLabel:TpvGUILabel);
begin
end;

procedure TpvGUISkin.DrawButton(const aCanvas:TpvCanvas;const aButton:TpvGUIButton);
begin
end;

constructor TpvGUIDefaultVectorBasedSkin.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
end;

destructor TpvGUIDefaultVectorBasedSkin.Destroy;
begin
 inherited Destroy;
end;

procedure TpvGUIDefaultVectorBasedSkin.Setup;
var Stream:TStream;
    TrueTypeFont:TpvTrueTypeFont;
begin

 fFontSize:=-12;

 fUnfocusedWindowHeaderFontSize:=-16;
 fFocusedWindowHeaderFontSize:=-16;

 fUnfocusedWindowHeaderFontShadow:=true;
 fFocusedWindowHeaderFontShadow:=true;

 fUnfocusedWindowHeaderFontShadowOffset:=TpvVector2.Create(2.0,2.0);
 fFocusedWindowHeaderFontShadowOffset:=TpvVector2.Create(2.0,2.0);

 fUnfocusedWindowHeaderFontShadowColor:=TpvVector4.Create(0.0,0.0,0.0,0.3275);
 fFocusedWindowHeaderFontShadowColor:=TpvVector4.Create(0.0,0.0,0.0,0.5);

 fUnfocusedWindowHeaderFontColor:=TpvVector4.Create(0.75,0.75,0.75,1.0);
 fFocusedWindowHeaderFontColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);

 fLabelFontColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);

 fWindowHeaderHeight:=32;

 fWindowResizeGripSize:=8;

 fWindowMinimumWidth:=Max(fWindowHeaderHeight+8,fWindowResizeGripSize*2);
 fWindowMinimumHeight:=Max(fWindowHeaderHeight+8,fWindowResizeGripSize*2);

 fWindowShadowWidth:=16;
 fWindowShadowHeight:=16;

 fFontSpriteAtlas:=TpvSpriteAtlas.Create(fInstance.fVulkanDevice,false);

 Stream:=TpvDataStream.Create(@GUIStandardTrueTypeFontSansFontData,GUIStandardTrueTypeFontSansFontDataSize);
 try
  TrueTypeFont:=TpvTrueTypeFont.Create(Stream,72);
  try
   TrueTypeFont.Size:=-64;
   TrueTypeFont.Hinting:=false;
   fSansFont:=TpvFont.CreateFromTrueTypeFont(pvApplication.VulkanDevice,
                                             fFontSpriteAtlas,
                                             TrueTypeFont,
                                             [TpvFontCodePointRange.Create(0,255)]);
  finally
   TrueTypeFont.Free;
  end;
 finally
  Stream.Free;
 end;

 Stream:=TpvDataStream.Create(@GUIStandardTrueTypeFontMonoFontData,GUIStandardTrueTypeFontMonoFontDataSize);
 try
  TrueTypeFont:=TpvTrueTypeFont.Create(Stream,72);
  try
   TrueTypeFont.Size:=-64;
   TrueTypeFont.Hinting:=false;
   fMonoFont:=TpvFont.CreateFromTrueTypeFont(pvApplication.VulkanDevice,
                                             fFontSpriteAtlas,
                                             TrueTypeFont,
                                             [TpvFontCodePointRange.Create(0,255)]);
  finally
   TrueTypeFont.Free;
  end;
 finally
  Stream.Free;
 end;

 fFontSpriteAtlas.MipMaps:=false;
 fFontSpriteAtlas.Upload(pvApplication.VulkanDevice.GraphicsQueue,
                         pvApplication.VulkanGraphicsCommandBuffers[0,0],
                         pvApplication.VulkanGraphicsCommandBufferFences[0,0],
                         pvApplication.VulkanDevice.TransferQueue,
                         pvApplication.VulkanTransferCommandBuffers[0,0],
                         pvApplication.VulkanTransferCommandBufferFences[0,0]);

end;

procedure TpvGUIDefaultVectorBasedSkin.DrawMouse(const aCanvas:TpvCanvas;const aInstance:TpvGUIInstance);
var LastModelMatrix:TpvMatrix4x4;
begin
 LastModelMatrix:=aCanvas.ModelMatrix;
 try
  aCanvas.ModelMatrix:=TpvMatrix4x4.CreateTranslation(aInstance.fMousePosition)*LastModelMatrix;
  case aInstance.fVisibleCursor of
   pvgcArrow:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_ARROW,
                           false,
                           TpvVector2.Create(2.0,2.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(2.0,2.0),
                           TpvVector2.Create(34.0,34.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_ARROW,
                           true,
                           TpvVector2.Null,
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Null,
                           TpvVector2.Create(32.0,32.0));
   end;
   pvgcBeam:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_BEAM,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_BEAM,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcBusy:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_BUSY,
                           false,
                           TpvVector2.Create(-18.0,-18.0),
                           TpvVector2.Create(22.0,22.0),
                           TpvVector2.Create(-8.0,-8.0),
                           TpvVector2.Create(12.0,12.0),
                           frac(aInstance.fTime)*TwoPI);
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_BUSY,
                           true,
                           TpvVector2.Create(-20.0,-20.0),
                           TpvVector2.Create(20.0,20.0),
                           TpvVector2.Create(-10.0,-10.0),
                           TpvVector2.Create(10.0,10.0),
                           frac(aInstance.fTime)*TwoPI);
   end;
   pvgcCross:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_CROSS,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_CROSS,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcEW:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_EW,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_EW,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcHelp:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_HELP,
                           false,
                           TpvVector2.Create(2.0,2.0),
                           TpvVector2.Create(64.0,64.0),
                           TpvVector2.Create(2.0,2.0),
                           TpvVector2.Create(34.0,34.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_HELP,
                           true,
                           TpvVector2.Null,
                           TpvVector2.Create(64.0,64.0),
                           TpvVector2.Null,
                           TpvVector2.Create(32.0,32.0));
   end;
   pvgcLink:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_LINK,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(2.0,2.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_LINK,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Null,
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcMove:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_MOVE,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_MOVE,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcNESW:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_NESW,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_NESW,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcNS:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_NS,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_NS,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcNWSE:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_NWSE,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_NWSE,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcPen:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_PEN,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_PEN,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
   pvgcUnavailable:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_UNAVAILABLE,
                           false,
                           TpvVector2.Create(-18.0,-18.0),
                           TpvVector2.Create(22.0,22.0),
                           TpvVector2.Create(-8.0,-8.0),
                           TpvVector2.Create(12.0,12.0),
                           frac(aInstance.fTime)*TwoPI);
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_UNAVAILABLE,
                           true,
                           TpvVector2.Create(-20.0,-20.0),
                           TpvVector2.Create(20.0,20.0),
                           TpvVector2.Create(-10.0,-10.0),
                           TpvVector2.Create(10.0,10.0));
   end;
   pvgcUp:begin
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_UP,
                           false,
                           TpvVector2.Create(-30.0,-30.0),
                           TpvVector2.Create(34.0,34.0),
                           TpvVector2.Create(-14.0,-14.0),
                           TpvVector2.Create(18.0,18.0));
    aCanvas.DrawGUIElement(GUI_ELEMENT_MOUSE_CURSOR_UP,
                           true,
                           TpvVector2.Create(-32.0,-32.0),
                           TpvVector2.Create(32.0,32.0),
                           TpvVector2.Create(-16.0,-16.0),
                           TpvVector2.Create(16.0,16.0));
   end;
  end;
 finally
  aCanvas.ModelMatrix:=LastModelMatrix;
 end;
end;

procedure TpvGUIDefaultVectorBasedSkin.DrawWindow(const aCanvas:TpvCanvas;const aWindow:TpvGUIWindow);
var LastClipRect,NewClipRect:TpvRect;
    LastModelMatrix,NewModelMatrix:TpvMatrix4x4;
    LastLinearColor:TpvVector4;
begin
 LastLinearColor:=aCanvas.LinearColor;
 try

  aCanvas.LinearColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);

  LastClipRect:=aCanvas.ClipRect;
  try
   NewClipRect:=TpvRect.CreateAbsolute(LastClipRect.Left-fWindowShadowWidth,
                                       LastClipRect.Top-fWindowShadowHeight,
                                       LastClipRect.Right+fWindowShadowWidth,
                                       LastClipRect.Bottom+fWindowShadowHeight);
   if assigned(fParent) and
      (fParent is TpvGUIWidget) then begin
    NewClipRect:=TpvRect.CreateRelative((fParent as TpvGUIWidget).fPosition,
                                        (fParent as TpvGUIWidget).fSize).GetIntersection(NewClipRect);
   end;
   aCanvas.ClipRect:=NewClipRect;
   aCanvas.DrawGUIElement(GUI_ELEMENT_WINDOW_DROPSHADOW,
                         aWindow.Focused,
                         TpvVector2.Create(-fWindowShadowWidth,-fWindowShadowHeight),
                         aWindow.fSize+TpvVector2.Create(fWindowShadowWidth*2,fWindowShadowHeight*2),
                         TpvVector2.Create(0.0,0.0),
                         aWindow.fSize);
  finally
   aCanvas.ClipRect:=LastClipRect;
  end;

  if pvgwfHeader in aWindow.fWindowFlags then begin

   aCanvas.DrawGUIElement(GUI_ELEMENT_WINDOW_FILL,
                          aWindow.Focused,
                          TpvVector2.Create(0.0,fWindowHeaderHeight-8),
                          TpvVector2.Create(aWindow.fSize.x,aWindow.fSize.y),
                          TpvVector2.Create(0.0,fWindowHeaderHeight-8),
                          TpvVector2.Create(aWindow.fSize.x,aWindow.fSize.y));

   aCanvas.DrawGUIElement(GUI_ELEMENT_WINDOW_HEADER,
                          aWindow.Focused,
                          TpvVector2.Create(0.0,0.0),
                          TpvVector2.Create(aWindow.fSize.x,fWindowHeaderHeight),
                          TpvVector2.Create(0.0,0.0),
                          TpvVector2.Create(aWindow.fSize.x,fWindowHeaderHeight));

   LastClipRect:=aCanvas.ClipRect;
   LastClipRect.LeftTop:=LastClipRect.LeftTop+TpvVector2.Create(1.0,1.0);
   LastClipRect.RightBottom:=LastClipRect.RightBottom-TpvVector2.Create(1.0,1.0);
   aCanvas.ClipRect:=LastClipRect;

   LastModelMatrix:=aCanvas.ModelMatrix;
   try
    aCanvas.Font:=fSansFont;
    aCanvas.FontSize:=IfThen(pvgwfFocused in aWindow.fWidgetFlags,fFocusedWindowHeaderFontSize,fUnfocusedWindowHeaderFontSize);
    aCanvas.TextHorizontalAlignment:=pvcthaCenter;
    aCanvas.TextVerticalAlignment:=pvctvaMiddle;
    NewModelMatrix:=TpvMatrix4x4.CreateTranslation(aWindow.fSize.x*0.5,
                                                   fWindowHeaderHeight*0.5)*
                    LastModelMatrix;
    if ((pvgwfFocused in aWindow.fWidgetFlags) and fFocusedWindowHeaderFontShadow) or
       ((not (pvgwfFocused in aWindow.fWidgetFlags)) and fUnfocusedWindowHeaderFontShadow) then begin
     if pvgwfFocused in aWindow.fWidgetFlags then begin
      aCanvas.ModelMatrix:=TpvMatrix4x4.CreateTranslation(fFocusedWindowHeaderFontShadowOffset)*NewModelMatrix;
      aCanvas.SRGBColor:=fFocusedWindowHeaderFontShadowColor;
     end else begin
      aCanvas.ModelMatrix:=TpvMatrix4x4.CreateTranslation(fUnfocusedWindowHeaderFontShadowOffset)*NewModelMatrix;
      aCanvas.SRGBColor:=fUnfocusedWindowHeaderFontShadowColor;
     end;
     aCanvas.DrawText(aWindow.fTitle);
    end;
    aCanvas.ModelMatrix:=NewModelMatrix;
    if pvgwfFocused in aWindow.fWidgetFlags then begin
     aCanvas.SRGBColor:=fFocusedWindowHeaderFontColor;
    end else begin
     aCanvas.SRGBColor:=fUnfocusedWindowHeaderFontColor;
    end;
    aCanvas.DrawText(aWindow.fTitle);
   finally
    aCanvas.ModelMatrix:=LastModelMatrix;
   end;

  end else begin

   aCanvas.DrawGUIElement(GUI_ELEMENT_WINDOW_FILL,
                          aWindow.Focused,
                          TpvVector2.Create(0.0,0.0),
                          TpvVector2.Create(aWindow.fSize.x,aWindow.fSize.y),
                          TpvVector2.Create(0.0,0.0),
                          TpvVector2.Create(aWindow.fSize.x,aWindow.fSize.y));

   LastClipRect:=aCanvas.ClipRect;
   LastClipRect.LeftTop:=LastClipRect.LeftTop+TpvVector2.Create(1.0,1.0);
   LastClipRect.RightBottom:=LastClipRect.RightBottom-TpvVector2.Create(1.0,1.0);
   aCanvas.ClipRect:=LastClipRect;

  end;

 finally
  aCanvas.LinearColor:=LastLinearColor;
 end;
end;

procedure TpvGUIDefaultVectorBasedSkin.DrawLabel(const aCanvas:TpvCanvas;const aLabel:TpvGUILabel);
begin
 aCanvas.Font:=fSansFont;
 aCanvas.FontSize:=aLabel.FontSize;
 aCanvas.TextHorizontalAlignment:=pvcthaLeft;
 aCanvas.TextVerticalAlignment:=pvctvaTop;
 aCanvas.SRGBColor:=fLabelFontColor;
 aCanvas.DrawText(aLabel.fCaption);
end;

procedure TpvGUIDefaultVectorBasedSkin.DrawButton(const aCanvas:TpvCanvas;const aButton:TpvGUIButton);
begin

 if not aButton.Enabled then begin

  aCanvas.DrawGUIElement(GUI_ELEMENT_BUTTON_DISABLED,
                         true,
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y),
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y));

  aCanvas.Font:=fSansFont;
  aCanvas.FontSize:=aButton.FontSize;
  aCanvas.TextHorizontalAlignment:=pvcthaCenter;
  aCanvas.TextVerticalAlignment:=pvctvaMiddle;
  aCanvas.SRGBColor:=TpvVector4.Create(0.0,0.0,0.0,1.0);
  aCanvas.DrawText(aButton.fCaption,aButton.fSize*0.5);

 end else if aButton.Down then begin

  aCanvas.DrawGUIElement(GUI_ELEMENT_BUTTON_PUSHED,
                         true,
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y),
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y));

  aCanvas.Font:=fSansFont;
  aCanvas.FontSize:=aButton.FontSize;
  aCanvas.TextHorizontalAlignment:=pvcthaCenter;
  aCanvas.TextVerticalAlignment:=pvctvaMiddle;
  aCanvas.SRGBColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);
  aCanvas.DrawText(aButton.fCaption,aButton.fSize*0.5);

 end else if aButton.Focused then begin

  aCanvas.DrawGUIElement(GUI_ELEMENT_BUTTON_FOCUSED,
                         true,
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y),
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y));

  aCanvas.Font:=fSansFont;
  aCanvas.FontSize:=aButton.FontSize;
  aCanvas.TextHorizontalAlignment:=pvcthaCenter;
  aCanvas.TextVerticalAlignment:=pvctvaMiddle;
  aCanvas.SRGBColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);
  aCanvas.DrawText(aButton.fCaption,aButton.fSize*0.5);

 end else begin

  aCanvas.DrawGUIElement(GUI_ELEMENT_BUTTON_UNFOCUSED,
                         true,
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y),
                         TpvVector2.Create(0.0,0.0),
                         TpvVector2.Create(aButton.fSize.x,aButton.fSize.y));

  aCanvas.Font:=fSansFont;
  aCanvas.FontSize:=aButton.FontSize;
  aCanvas.TextHorizontalAlignment:=pvcthaCenter;
  aCanvas.TextVerticalAlignment:=pvctvaMiddle;
  aCanvas.SRGBColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);
  aCanvas.DrawText(aButton.fCaption,aButton.fSize*0.5);

 end;

end;

constructor TpvGUIWidgetEnumerator.Create(const aWidget:TpvGUIWidget);
begin
 inherited Create;
 fWidget:=aWidget;
 fIndex:=-1;
end;

function TpvGUIWidgetEnumerator.DoMoveNext:boolean;
begin
 inc(fIndex);
 while (fIndex<fWidget.fChildren.Count) and not (fWidget.fChildren[fIndex] is TpvGUIWidget) do begin
  inc(fIndex);
 end;
 result:=(fWidget.fChildren.Count<>0) and (fIndex<fWidget.fChildren.Count);
end;

function TpvGUIWidgetEnumerator.DoGetCurrent:TpvGUIWidget;
begin
 result:=fWidget.fChildren[fIndex] as TpvGUIWidget;
end;

constructor TpvGUIWidget.Create(const aParent:TpvGUIObject);
begin

 inherited Create(aParent);

 fCanvas:=nil;

 fLayout:=nil;

 fSkin:=nil;

 fCursor:=pvgcArrow;

 fPosition:=TpvVector2.Create(0.0,0.0);

 fSize:=TpvVector2.Create(1.0,1.0);

 fFixedSize:=TpvVector2.Create(-1.0,-1.0);

 fPositionProperty:=TpvVector2Property.Create(@fPosition);

 fSizeProperty:=TpvVector2Property.Create(@fSize);

 fFixedSizeProperty:=TpvVector2Property.Create(@fFixedSize);

 fWidgetFlags:=TpvGUIWidget.DefaultFlags;

 fHint:='';

 fFontSize:=0.0;

end;

destructor TpvGUIWidget.Destroy;
begin

 FreeAndNil(fPositionProperty);

 FreeAndNil(fSizeProperty);

 FreeAndNil(fFixedSizeProperty);

 inherited Destroy;

end;

procedure TpvGUIWidget.AfterConstruction;
begin
 inherited AfterConstruction;
end;

procedure TpvGUIWidget.BeforeDestruction;
begin
 inherited BeforeDestruction;
end;

procedure TpvGUIWidget.SetCanvas(const aCanvas:TpvCanvas);
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 fCanvas:=aCanvas;
 for ChildIndex:=0 to fChildren.Count-1 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   ChildWidget.SetCanvas(aCanvas);
  end;
 end;
end;

function TpvGUIWidget.GetSkin:TpvGUISkin;
begin
 if assigned(fSkin) then begin
  result:=fSkin;
 end else if assigned(fInstance) then begin
  result:=fInstance.fStandardSkin;
 end else begin
  result:=nil;
 end;
end;

procedure TpvGUIWidget.SetSkin(const aSkin:TpvGUISkin);
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 fSkin:=aSkin;
 for ChildIndex:=0 to fChildren.Count-1 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   ChildWidget.SetSkin(aSkin);
  end;
 end;
end;

function TpvGUIWidget.GetEnabled:boolean;
begin
 result:=pvgwfEnabled in fWidgetFlags;
end;

procedure TpvGUIWidget.SetEnabled(const aEnabled:boolean);
begin
 if aEnabled then begin
  Include(fWidgetFlags,pvgwfEnabled);
 end else begin
  Exclude(fWidgetFlags,pvgwfEnabled);
 end;
end;

function TpvGUIWidget.GetVisible:boolean;
begin
 result:=pvgwfVisible in fWidgetFlags;
end;

procedure TpvGUIWidget.SetVisible(const aVisible:boolean);
begin
 if aVisible then begin
  Include(fWidgetFlags,pvgwfVisible);
 end else begin
  Exclude(fWidgetFlags,pvgwfVisible);
 end;
end;

function TpvGUIWidget.GetFocused:boolean;
begin
 result:=pvgwfFocused in fWidgetFlags;
end;

procedure TpvGUIWidget.SetFocused(const aFocused:boolean);
begin
 if aFocused then begin
  Include(fWidgetFlags,pvgwfFocused);
 end else begin
  Exclude(fWidgetFlags,pvgwfFocused);
 end;
end;

function TpvGUIWidget.GetPointerFocused:boolean;
begin
 result:=pvgwfPointerFocused in fWidgetFlags;
end;

procedure TpvGUIWidget.SetPointerFocused(const aPointerFocused:boolean);
begin
 if aPointerFocused then begin
  Include(fWidgetFlags,pvgwfPointerFocused);
 end else begin
  Exclude(fWidgetFlags,pvgwfPointerFocused);
 end;
end;

function TpvGUIWidget.GetLeft:TpvFloat;
begin
 result:=fPosition.x;
end;

procedure TpvGUIWidget.SetLeft(const aLeft:TpvFloat);
begin
 fPosition.x:=aLeft;
end;

function TpvGUIWidget.GetTop:TpvFloat;
begin
 result:=fPosition.y;
end;

procedure TpvGUIWidget.SetTop(const aTop:TpvFloat);
begin
 fPosition.y:=aTop;
end;

function TpvGUIWidget.GetWidth:TpvFloat;
begin
 result:=fSize.x;
end;

procedure TpvGUIWidget.SetWidth(const aWidth:TpvFloat);
begin
 fSize.x:=aWidth;
end;

function TpvGUIWidget.GetHeight:TpvFloat;
begin
 result:=fSize.y;
end;

procedure TpvGUIWidget.SetHeight(const aHeight:TpvFloat);
begin
 fSize.y:=aHeight;
end;

function TpvGUIWidget.GetFixedWidth:TpvFloat;
begin
 result:=fFixedSize.x;
end;

procedure TpvGUIWidget.SetFixedWidth(const aFixedWidth:TpvFloat);
begin
 fFixedSize.x:=aFixedWidth;
end;

function TpvGUIWidget.GetFixedHeight:TpvFloat;
begin
 result:=fFixedSize.y;
end;

procedure TpvGUIWidget.SetFixedHeight(const aFixedHeight:TpvFloat);
begin
 fFixedSize.y:=aFixedHeight;
end;

function TpvGUIWidget.GetAbsolutePosition:TpvVector2;
begin
 if assigned(fParent) and (fParent is TpvGUIWidget) then begin
  result:=(fParent as TpvGUIWidget).AbsolutePosition+fPosition;
 end else begin
  result:=fPosition;
 end;
end;

function TpvGUIWidget.GetRecursiveVisible:boolean;
var CurrentWidget:TpvGUIWidget;
begin
 CurrentWidget:=self;
 repeat
  result:=CurrentWidget.Visible;
  if result and assigned(CurrentWidget.fParent) and (CurrentWidget.fParent is TpvGUIWidget) then begin
   CurrentWidget:=CurrentWidget.fParent as TpvGUIWidget;
  end else begin
   break;
  end;
 until false;
end;

function TpvGUIWidget.GetPreferredSize:TpvVector2;
begin
 if assigned(fLayout) then begin
  result:=fLayout.GetPreferredSize(self);
 end else begin
  result:=fSize;
 end;
end;

function TpvGUIWidget.GetFontSize:TpvFloat;
begin
 if assigned(Skin) and IsZero(fFontSize) then begin
  result:=Skin.fFontSize;
 end else begin
  result:=fFontSize;
 end;
end;

function TpvGUIWidget.GetEnumerator:TpvGUIWidgetEnumerator;
begin
 result:=TpvGUIWidgetEnumerator.Create(self);
end;

function TpvGUIWidget.Contains(const aPosition:TpvVector2):boolean;
begin
 result:=(aPosition.x>=0.0) and
         (aPosition.y>=0.0) and
         (aPosition.x<fSize.x) and
         (aPosition.y<fSize.y);
end;

function TpvGUIWidget.FindWidget(const aPosition:TpvVector2):TpvGUIWidget;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
    ChildPosition:TpvVector2;
begin
 for ChildIndex:=fChildren.Count-1 downto 0 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   if ChildWidget.Visible then begin
    ChildPosition:=aPosition-ChildWidget.fPosition;
    if ChildWidget.Contains(ChildPosition) then begin
     result:=ChildWidget.FindWidget(ChildPosition);
     exit;
    end;
   end;
  end;
 end;
 if Contains(aPosition) then begin
  result:=self;
 end else begin
  result:=nil;
 end;
end;

function TpvGUIWidget.GetWindow:TpvGUIWindow;
var CurrentWidget:TpvGUIWidget;
begin
 result:=nil;
 CurrentWidget:=self;
 while assigned(CurrentWidget) do begin
  if CurrentWidget is TpvGUIWindow then begin
   result:=CurrentWidget as TpvGUIWindow;
   exit;
  end else begin
   if assigned(CurrentWidget.Parent) and (CurrentWidget.Parent is TpvGUIWidget) then begin
    CurrentWidget:=CurrentWidget.fParent as TpvGUIWidget;
   end else begin
    break;
   end;
  end;
 end;
 raise EpvGUIWidget.Create('Could not find parent window');
end;

procedure TpvGUIWidget.RequestFocus;
var CurrentWidget:TpvGUIWidget;
begin
 if assigned(fInstance) then begin
  fInstance.UpdateFocus(self);
 end else begin
  CurrentWidget:=self;
  while assigned(CurrentWidget) do begin
   if CurrentWidget is TpvGUIInstance then begin
    (CurrentWidget as TpvGUIInstance).UpdateFocus(self);
    break;
   end else begin
    if assigned(CurrentWidget.Parent) and (CurrentWidget.Parent is TpvGUIWidget) then begin
     CurrentWidget:=CurrentWidget.fParent as TpvGUIWidget;
    end else begin
     break;
    end;
   end;
  end;
 end;
end;

procedure TpvGUIWidget.PerformLayout;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
    ChildWidgetPreferredSize,ChildWidgetFixedSize,ChildWidgetSize:TpvVector2;
begin
 if assigned(fLayout) then begin
  fLayout.PerformLayout(self);
 end else begin
  for ChildIndex:=0 to fChildren.Count-1 do begin
   Child:=fChildren.Items[ChildIndex];
   if Child is TpvGUIWidget then begin
    ChildWidget:=Child as TpvGUIWidget;
    ChildWidgetPreferredSize:=ChildWidget.GetPreferredSize;
    ChildWidgetFixedSize:=ChildWidget.fFixedSize;
    if ChildWidgetFixedSize.x>0.0 then begin
     ChildWidgetSize.x:=ChildWidgetFixedSize.x;
    end else begin
     ChildWidgetSize.x:=ChildWidgetPreferredSize.x;
    end;
    if ChildWidgetFixedSize.y>0.0 then begin
     ChildWidgetSize.y:=ChildWidgetFixedSize.y;
    end else begin
     ChildWidgetSize.y:=ChildWidgetPreferredSize.y;
    end;
    ChildWidget.fSize:=ChildWidgetSize;
    ChildWidget.PerformLayout;
   end;
  end;
 end;
end;

function TpvGUIWidget.Enter:boolean;
begin
 Include(fWidgetFlags,pvgwfFocused);
 result:=false;
end;

function TpvGUIWidget.Leave:boolean;
begin
 Exclude(fWidgetFlags,pvgwfFocused);
 result:=false;
end;

function TpvGUIWidget.PointerEnter:boolean;
begin
 Include(fWidgetFlags,pvgwfPointerFocused);
 result:=false;
end;

function TpvGUIWidget.PointerLeave:boolean;
begin
 Exclude(fWidgetFlags,pvgwfPointerFocused);
 result:=false;
end;

function TpvGUIWidget.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
begin
 result:=false;
end;

function TpvGUIWidget.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
    ChildPointerEvent:TpvApplicationInputPointerEvent;
    PreviousContained,CurrentContained:boolean;
begin
 ChildPointerEvent:=aPointerEvent;
 for ChildIndex:=fChildren.Count-1 downto 0 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   if ChildWidget.Visible then begin
    case aPointerEvent.PointerEventType of
     POINTEREVENT_MOTION,POINTEREVENT_DRAG:begin
      ChildPointerEvent.Position:=aPointerEvent.Position-ChildWidget.fPosition;
      PreviousContained:=ChildWidget.Contains(ChildPointerEvent.Position-ChildPointerEvent.RelativePosition);
      CurrentContained:=ChildWidget.Contains(ChildPointerEvent.Position);
      if CurrentContained and not PreviousContained then begin
       ChildWidget.PointerEnter;
      end else if PreviousContained and not CurrentContained then begin
       ChildWidget.PointerLeave;
      end;
      if PreviousContained or CurrentContained then begin
       result:=ChildWidget.PointerEvent(ChildPointerEvent);
       if result then begin
        exit;
       end;
      end;
     end;
     else begin
      ChildPointerEvent.Position:=aPointerEvent.Position-ChildWidget.fPosition;
      if ChildWidget.Contains(ChildPointerEvent.Position) then begin
       result:=ChildWidget.PointerEvent(ChildPointerEvent);
       if result then begin
        exit;
       end;
      end;
     end;
    end;
   end;
  end;
 end;
 if (aPointerEvent.PointerEventType=POINTEREVENT_DOWN) and
    (aPointerEvent.Button=BUTTON_LEFT) and not
    (pvgwfFocused in fWidgetFlags) then begin
  RequestFocus;
 end;
 result:=false;
end;

function TpvGUIWidget.Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
    ChildPosition:TpvVector2;
begin
 for ChildIndex:=fChildren.Count-1 downto 0 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   if ChildWidget.Visible then begin
    ChildPosition:=aPosition-ChildWidget.fPosition;
    if ChildWidget.Contains(ChildPosition) then begin
     result:=ChildWidget.Scrolled(ChildPosition,aRelativeAmount);
     if result then begin
      exit;
     end;
    end;
   end;
  end;
 end;
 result:=false;
end;

procedure TpvGUIWidget.AfterCreateSwapChain;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 for ChildIndex:=0 to fChildren.Count-1 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   ChildWidget.AfterCreateSwapChain;
  end;
 end;
end;

procedure TpvGUIWidget.BeforeDestroySwapChain;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 for ChildIndex:=0 to fChildren.Count-1 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   ChildWidget.BeforeDestroySwapChain;
  end;
 end;
end;

procedure TpvGUIWidget.Update;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
    BaseClipRect:TpvRect;
    BaseModelMatrix:TpvMatrix4x4;
begin
 BaseClipRect:=fCanvas.State.ClipRect;
 BaseModelMatrix:=fCanvas.ModelMatrix;
 try
  if fInstance.fDrawWidgetBounds then begin
   fCanvas.Push;
   try
    fCanvas.LinearColor:=TpvVector4.Create(1.0,1.0,1.0,1.0);
    fCanvas.LineWidth:=4.0;
    fCanvas.LineJoin:=pvcljRound;
    fCanvas.LineCap:=pvclcRound;
    fCanvas.BeginPath;
    fCanvas.MoveTo(0.0,0.0);
    fCanvas.LineTo(Width,0.0);
    fCanvas.LineTo(Width,Height);
    fCanvas.LineTo(0.0,Height);
    fCanvas.ClosePath;
    fCanvas.Stroke;
    fCanvas.EndPath;
   finally
    fCanvas.Pop;
   end;
  end;
  for ChildIndex:=0 to fChildren.Count-1 do begin
   Child:=fChildren.Items[ChildIndex];
   if Child is TpvGUIWidget then begin
    ChildWidget:=Child as TpvGUIWidget;
    fInstance.AddReferenceCountedObjectForNextDraw(ChildWidget);
    if ChildWidget.Visible then begin
     fCanvas.ClipRect:=BaseClipRect.GetIntersection(TpvRect.CreateRelative(BaseModelMatrix*ChildWidget.fPosition,
                                                                           ChildWidget.fSize));
     fCanvas.ModelMatrix:=TpvMatrix4x4.CreateTranslation(ChildWidget.Left,ChildWidget.Top)*BaseModelMatrix;
     ChildWidget.fCanvas:=fCanvas;
     ChildWidget.Update;
    end;
   end;
  end;
 finally
  fCanvas.ClipRect:=BaseClipRect;
  fCanvas.ModelMatrix:=BaseModelMatrix;
 end;
end;

procedure TpvGUIWidget.Draw;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 for ChildIndex:=0 to fChildren.Count-1 do begin
  Child:=fChildren.Items[ChildIndex];
  if Child is TpvGUIWidget then begin
   ChildWidget:=Child as TpvGUIWidget;
   if ChildWidget.Visible then begin
    ChildWidget.fCanvas:=fCanvas;
    ChildWidget.Draw;
   end;
  end;
 end;
end;

constructor TpvGUIInstance.Create(const aVulkanDevice:TpvVulkanDevice);
begin

 inherited Create(nil);

 fInstance:=self;

 fVulkanDevice:=aVulkanDevice;

 fStandardSkin:=TpvGUIDefaultVectorBasedSkin.Create(self);

 fDrawWidgetBounds:=false;

 fBuffers:=nil;

 fCountBuffers:=0;

 fUpdateBufferIndex:=0;

 fDrawBufferIndex:=0;

 fDeltaTime:=0.0;

 fTime:=0.0;

 fLastFocusPath:=TpvGUIObjectList.Create(false);

 fCurrentFocusPath:=TpvGUIObjectList.Create(false);

 fDragWidget:=nil;

 fWindow:=nil;

 fVisibleCursor:=pvgcArrow;

 SetCountBuffers(1);

end;

destructor TpvGUIInstance.Destroy;
begin

 TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);

 FreeAndNil(fLastFocusPath);

 FreeAndNil(fCurrentFocusPath);

 SetCountBuffers(0);

 fBuffers:=nil;

 inherited Destroy;

end;

procedure TpvGUIInstance.SetCountBuffers(const aCountBuffers:TpvInt32);
var Index,SubIndex:TpvInt32;
    Buffer:PpvGUIInstanceBuffer;
begin

 if fCountBuffers<>aCountBuffers then begin

  for Index:=aCountBuffers to fCountBuffers-1 do begin
   Buffer:=@fBuffers[Index];
   for SubIndex:=0 to Buffer^.CountReferenceCountedObjects-1 do begin
    Buffer^.ReferenceCountedObjects[SubIndex].DecRef;
   end;
   Buffer^.CountReferenceCountedObjects:=0;
  end;

  if length(fBuffers)<aCountBuffers then begin
   SetLength(fBuffers,aCountBuffers*2);
   for Index:=Max(0,fCountBuffers) to length(fBuffers)-1 do begin
    fBuffers[Index].CountReferenceCountedObjects:=0;
   end;
  end;

  for Index:=fCountBuffers to aCountBuffers-1 do begin
   fBuffers[Index].CountReferenceCountedObjects:=0;
  end;

  fCountBuffers:=aCountBuffers;

 end;

end;

procedure TpvGUIInstance.AfterConstruction;
begin
 inherited AfterConstruction;
 IncRef;
end;

procedure TpvGUIInstance.BeforeDestruction;
begin
 TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);
 TpvReferenceCountedObject.DecRefOrFreeAndNil(fWindow);
 fLastFocusPath.Clear;
 fCurrentFocusPath.Clear;
 DecRefWithoutFree;
 inherited BeforeDestruction;
end;

procedure TpvGUIInstance.SetUpdateBufferIndex(const aUpdateBufferIndex:TpvInt32);
begin
 fUpdateBufferIndex:=aUpdateBufferIndex;
end;

procedure TpvGUIInstance.SetDrawBufferIndex(const aDrawBufferIndex:TpvInt32);
begin
 fDrawBufferIndex:=aDrawBufferIndex;
end;

procedure TpvGUIInstance.ClearReferenceCountedObjectList;
var Index:TpvInt32;
    Buffer:PpvGUIInstanceBuffer;
begin
 if (fUpdateBufferIndex>=0) and (fUpdateBufferIndex<fCountBuffers) then begin
  Buffer:=@fBuffers[fUpdateBufferIndex];
  for Index:=0 to Buffer^.CountReferenceCountedObjects-1 do begin
   Buffer^.ReferenceCountedObjects[Index].DecRef;
  end;
  Buffer^.CountReferenceCountedObjects:=0;
 end;
end;

procedure TpvGUIInstance.AddReferenceCountedObjectForNextDraw(const aObject:TpvReferenceCountedObject);
var Index:TpvInt32;
    Buffer:PpvGUIInstanceBuffer;
begin
 if assigned(aObject) and ((fUpdateBufferIndex>=0) and (fUpdateBufferIndex<fCountBuffers)) then begin
  Buffer:=@fBuffers[fUpdateBufferIndex];
  Index:=Buffer^.CountReferenceCountedObjects;
  inc(Buffer^.CountReferenceCountedObjects);
  if length(Buffer^.ReferenceCountedObjects)<Buffer^.CountReferenceCountedObjects then begin
   SetLength(Buffer^.ReferenceCountedObjects,Buffer^.CountReferenceCountedObjects*2);
  end;
  Buffer^.ReferenceCountedObjects[Index]:=aObject;
  aObject.IncRef;
 end;
end;

procedure TpvGUIInstance.UpdateFocus(const aWidget:TpvGUIWidget);
var CurrentIndex:TpvInt32;
    Current:TpvGUIObject;
    CurrentWidget:TpvGUIWidget;
begin

 TpvSwap<TpvGUIObjectList>.Swap(fCurrentFocusPath,fLastFocusPath);

 fCurrentFocusPath.Clear;

 TpvReferenceCountedObject.DecRefOrFreeAndNil(fWindow);

 CurrentWidget:=aWidget;
 while assigned(CurrentWidget) do begin
  fCurrentFocusPath.Add(CurrentWidget);
  if CurrentWidget is TpvGUIWindow then begin
   TpvReferenceCountedObject.DecRefOrFreeAndNil(fWindow);
   fWindow:=CurrentWidget as TpvGUIWindow;
   fWindow.IncRef;
   break;
  end;
  if assigned(CurrentWidget.fParent) and (CurrentWidget.fParent is TpvGUIWidget) then begin
   CurrentWidget:=CurrentWidget.fParent as TpvGUIWidget;
  end else begin
   break;
  end;
 end;

 try
  for CurrentIndex:=0 to fLastFocusPath.Count-1 do begin
   Current:=fLastFocusPath.Items[CurrentIndex];
   if Current is TpvGUIWidget then begin
    CurrentWidget:=Current as TpvGUIWidget;
    if CurrentWidget.Focused and not fCurrentFocusPath.Contains(Current) then begin
     CurrentWidget.Leave;
    end;
   end;
  end;
 finally
  fLastFocusPath.Clear;
 end;

 for CurrentIndex:=0 to fCurrentFocusPath.Count-1 do begin
  Current:=fCurrentFocusPath.Items[CurrentIndex];
  if Current is TpvGUIWidget then begin
   CurrentWidget:=Current as TpvGUIWidget;
   CurrentWidget.Enter;
  end;
 end;

 if assigned(fWindow) then begin
  MoveWindowToFront(fWindow);
 end;

end;

procedure TpvGUIInstance.DisposeWindow(const aWindow:TpvGUIWindow);
begin
 if assigned(aWindow) then begin
  if assigned(fLastFocusPath) and fLastFocusPath.Contains(aWindow) then begin
   fLastFocusPath.Clear;
  end;
  if assigned(fCurrentFocusPath) and fCurrentFocusPath.Contains(aWindow) then begin
   fCurrentFocusPath.Clear;
  end;
  if fDragWidget=aWindow then begin
   TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);
  end;
  if assigned(fChildren) and fChildren.Contains(aWindow) then begin
   fChildren.Remove(aWindow);
  end;
 end;
end;

procedure TpvGUIInstance.CenterWindow(const aWindow:TpvGUIWindow);
begin
 if assigned(aWindow) then begin
  if aWindow.fSize=TpvVector2.Null then begin
   aWindow.fSize:=aWindow.PreferredSize;
   aWindow.PerformLayout;
  end;
  aWindow.fPosition:=(fSize-aWindow.fSize)*0.5;
 end;
end;

procedure TpvGUIInstance.MoveWindowToFront(const aWindow:TpvGUIWindow);
var Index,BaseIndex:TpvInt32;
    Changed:boolean;
    Current:TpvGUIObject;
//  PopupWidget:TpvGUIPopup;
begin
 if assigned(aWindow) then begin
  Index:=fChildren.IndexOf(aWindow);
  if Index>=0 then begin
   if Index<>(fChildren.Count-1) then begin
    fChildren.Move(Index,fChildren.Count-1);
   end;
   repeat
    Changed:=false;
    BaseIndex:=0;
    for Index:=0 to fChildren.Count-1 do begin
     if fChildren[Index]=aWindow then begin
      BaseIndex:=Index;
      break;
     end;
    end;
    for Index:=0 to fChildren.Count-1 do begin
     Current:=fChildren[Index];
     if assigned(Current) then begin
{     if Current is TpvGUIPopup then begin
       PopupWidget:=Current as TpvGUIPopup;
       if (PopupWidget.ParentWindow=aWindow) and (Index<BaseIndex) then begin
        MoveWindowToFront(PopupWidget);
        Changed:=true;
        break;
       end;
      end;}
     end;
    end;
   until not Changed;
  end;
 end;
end;

function TpvGUIInstance.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
var Index:TpvInt32;
    Current:TpvGUIObject;
    CurrentWidget:TpvGUIWidget;
begin
 result:=false;
 for Index:=0 to fCurrentFocusPath.Count-1 do begin
  Current:=fCurrentFocusPath.Items[Index];
  if (Current<>self) and (Current is TpvGUIWidget) then begin
   CurrentWidget:=Current as TpvGUIWidget;
   if CurrentWidget.Focused then begin
    result:=CurrentWidget.KeyEvent(aKeyEvent);
    if result then begin
     exit;
    end;
   end;
  end;
 end;
end;

function TpvGUIInstance.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
var Index:TpvInt32;
    Current:TpvGUIObject;
    CurrentWindow:TpvGUIWindow;
    CurrentWidget:TpvGUIWidget;
    LocalPointerEvent:TpvApplicationInputPointerEvent;
    DoUpdateCursor:boolean;
begin
 result:=false;
 DoUpdateCursor:=false;
 fMousePosition:=aPointerEvent.Position;
 case aPointerEvent.PointerEventType of
  POINTEREVENT_DOWN,POINTEREVENT_UP:begin
   for Index:=0 to fCurrentFocusPath.Count-1 do begin
    Current:=fCurrentFocusPath.Items[Index];
    if (Current<>self) and (Current is TpvGUIWindow) then begin
     CurrentWindow:=Current as TpvGUIWindow;
     if (pvgwfModal in CurrentWindow.fWindowFlags) and not CurrentWindow.Contains(aPointerEvent.Position-CurrentWindow.AbsolutePosition) then begin
      exit;
     end;
    end;
   end;
   case aPointerEvent.PointerEventType of
    POINTEREVENT_DOWN:begin
     case aPointerEvent.Button of
      BUTTON_LEFT,BUTTON_RIGHT:begin
       TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);
       CurrentWidget:=FindWidget(aPointerEvent.Position);
       if assigned(CurrentWidget) and (CurrentWidget<>self) then begin
        fDragWidget:=CurrentWidget;
        fDragWidget.IncRef;
       end else begin
        TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);
        UpdateFocus(nil);
       end;
      end;
      else begin
       TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);
      end;
     end;
    end;
    POINTEREVENT_UP:begin
     CurrentWidget:=FindWidget(aPointerEvent.Position);
     if assigned(fDragWidget) and (fDragWidget<>CurrentWidget) then begin
      LocalPointerEvent.PointerEventType:=POINTEREVENT_UP;
      LocalPointerEvent.Button:=BUTTON_LEFT;
      fDragWidget.PointerEvent(LocalPointerEvent);
     end;
     TpvReferenceCountedObject.DecRefOrFreeAndNil(fDragWidget);
    end;
   end;
   result:=inherited PointerEvent(aPointerEvent);
   DoUpdateCursor:=true;
  end;
  POINTEREVENT_MOTION:begin
   if assigned(fDragWidget) then begin
    LocalPointerEvent:=aPointerEvent;
    LocalPointerEvent.PointerEventType:=POINTEREVENT_DRAG;
    result:=fDragWidget.PointerEvent(LocalPointerEvent);
   end else begin
    result:=inherited PointerEvent(aPointerEvent);
   end;
   DoUpdateCursor:=true;
  end;
  POINTEREVENT_DRAG:begin
   result:=inherited PointerEvent(aPointerEvent);
  end;
 end;
 if DoUpdateCursor then begin
  if assigned(fDragWidget) then begin
   fVisibleCursor:=fDragWidget.fCursor;
  end else begin
   CurrentWidget:=FindWidget(aPointerEvent.Position);
   if assigned(CurrentWidget) then begin
    fVisibleCursor:=CurrentWidget.fCursor;
   end else begin
    fVisibleCursor:=fCursor;
   end;
  end;
 end;
end;

function TpvGUIInstance.Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean;
begin
 result:=inherited Scrolled(aPosition,aRelativeAmount);
end;

procedure TpvGUIInstance.Update;
begin
 ClearReferenceCountedObjectList;
 inherited Update;
 Skin.DrawMouse(fCanvas,self);
 fTime:=fTime+fDeltaTime;
end;

procedure TpvGUIInstance.Draw;
begin
 inherited Draw;
end;

constructor TpvGUIWindow.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fTitle:='Window';
 fMouseAction:=pvgwmaNone;
 fWindowFlags:=TpvGUIWindow.DefaultFlags;
 fButtonPanel:=nil;
end;

destructor TpvGUIWindow.Destroy;
begin
 inherited Destroy;
end;

procedure TpvGUIWindow.AfterConstruction;
begin
 inherited AfterConstruction;
end;

procedure TpvGUIWindow.BeforeDestruction;
begin
 if assigned(fInstance) then begin
  fInstance.DisposeWindow(self);
 end;
 inherited BeforeDestruction;
end;

procedure TpvGUIWindow.DisposeWindow;
begin
 if assigned(fInstance) then begin
  fInstance.DisposeWindow(self);
 end;
end;

function TpvGUIWindow.GetModal:boolean;
begin
 result:=pvgwfModal in fWindowFlags;
end;

procedure TpvGUIWindow.SetModal(const aModal:boolean);
begin
 if aModal then begin
  Include(fWindowFlags,pvgwfModal);
 end else begin
  Exclude(fWindowFlags,pvgwfModal);
 end;
end;

function TpvGUIWindow.GetButtonPanel:TpvGUIWidget;
begin
 if not assigned(fButtonPanel) then begin
  fButtonPanel:=TpvGUIWidget.Create(self);
  fButtonPanel.fLayout:=TpvGUIBoxLayout.Create(fButtonPanel,pvglaMiddle,pvgloHorizontal,0.0,4.0);
 end;
 result:=fButtonPanel;
end;

function TpvGUIWindow.GetPreferredSize:TpvVector2;
begin
 if assigned(fButtonPanel) then begin
  fButtonPanel.Visible:=false;
 end;
 result:=Maximum(inherited GetPreferredSize,
                 Skin.fSansFont.TextSize(fTitle,
                                          Max(Skin.fUnfocusedWindowHeaderFontSize,
                                              Skin.fFocusedWindowHeaderFontSize))+
                 TpvVector2.Create(Skin.fSansFont.TextWidth('====',
                                                             Max(Skin.fUnfocusedWindowHeaderFontSize,
                                                             Skin.fFocusedWindowHeaderFontSize)),
                                   0.0));
 if assigned(fButtonPanel) then begin
  fButtonPanel.Visible:=true;
 end;
end;

procedure TpvGUIWindow.PerformLayout;
var ChildIndex:TpvInt32;
    Child:TpvGUIObject;
    ChildWidget:TpvGUIWidget;
begin
 if assigned(fButtonPanel) then begin
  fButtonPanel.Visible:=false;
  inherited PerformLayout;
  fButtonPanel.Visible:=true;
  for ChildIndex:=0 to fButtonPanel.fChildren.Count-1 do begin
   Child:=fButtonPanel.fChildren.Items[ChildIndex];
   if Child is TpvGUIWidget then begin
    ChildWidget:=Child as TpvGUIWidget;
    ChildWidget.FixedWidth:=22;
    ChildWidget.FixedHeight:=22;
    ChildWidget.FontSize:=-15;
   end;
  end;
  fButtonPanel.Width:=Width;
  fButtonPanel.Height:=22;
  fButtonPanel.Left:=Width-(fButtonPanel.PreferredSize.x+5);
  fButtonPanel.Top:=3;
  fButtonPanel.PerformLayout;
 end else begin
  inherited PerformLayout;
 end;
end;

procedure TpvGUIWindow.RefreshRelativePlacement;
begin

end;

procedure TpvGUIWindow.Center;
begin
 if assigned(fInstance) then begin
  fInstance.CenterWindow(self);
 end;
end;

function TpvGUIWindow.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
begin
 result:=false;
end;

function TpvGUIWindow.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
var ClampedRelativePosition,MinimumSize,NewSize,NewPosition:TpvVector2;
begin
 result:=inherited PointerEvent(aPointerEvent);
 if not result then begin
  case aPointerEvent.PointerEventType of
   POINTEREVENT_DOWN:begin
    fMouseAction:=pvgwmaNone;
    fCursor:=pvgcArrow;
    if (pvgwfResizableNW in fWindowFlags) and
       (aPointerEvent.Position.x<Skin.fWindowResizeGripSize) and
       (aPointerEvent.Position.y<Skin.fWindowResizeGripSize) then begin
     fMouseAction:=pvgwmaSizeNW;
     fCursor:=pvgcNWSE;
    end else if (pvgwfResizableNE in fWindowFlags) and
                (aPointerEvent.Position.x>(fSize.x-Skin.fWindowResizeGripSize)) and
                (aPointerEvent.Position.y<Skin.fWindowResizeGripSize) then begin
     fMouseAction:=pvgwmaSizeNE;
     fCursor:=pvgcNESW;
    end else if (pvgwfResizableSW in fWindowFlags) and
                (aPointerEvent.Position.x<Skin.fWindowResizeGripSize) and
                (aPointerEvent.Position.y>(fSize.y-Skin.fWindowResizeGripSize)) then begin
     fMouseAction:=pvgwmaSizeSW;
     fCursor:=pvgcNESW;
    end else if (pvgwfResizableSE in fWindowFlags) and
                (aPointerEvent.Position.x>(fSize.x-Skin.fWindowResizeGripSize)) and
                (aPointerEvent.Position.y>(fSize.y-Skin.fWindowResizeGripSize)) then begin
     fMouseAction:=pvgwmaSizeSE;
     fCursor:=pvgcNWSE;
    end else if (pvgwfResizableN in fWindowFlags) and
                (aPointerEvent.Position.y<Skin.fWindowResizeGripSize) then begin
     fMouseAction:=pvgwmaSizeN;
     fCursor:=pvgcNS;
    end else if (pvgwfResizableS in fWindowFlags) and
                (aPointerEvent.Position.y>(fSize.y-Skin.fWindowResizeGripSize)) then begin
     fMouseAction:=pvgwmaSizeS;
     fCursor:=pvgcNS;
    end else if (pvgwfResizableW in fWindowFlags) and
                (aPointerEvent.Position.x<Skin.fWindowResizeGripSize) then begin
     fMouseAction:=pvgwmaSizeW;
     fCursor:=pvgcEW;
    end else if (pvgwfResizableE in fWindowFlags) and
                (aPointerEvent.Position.x>(fSize.x-Skin.fWindowResizeGripSize)) then begin
     fMouseAction:=pvgwmaSizeE;
     fCursor:=pvgcEW;
    end else if (pvgwfMovable in fWindowFlags) and
                (aPointerEvent.Position.y<Skin.fWindowHeaderHeight) then begin
     fMouseAction:=pvgwmaMove;
     fCursor:=pvgcMove;
    end;
    if not (pvgwfFocused in fWidgetFlags) then begin
     RequestFocus;
    end;
   end;
   POINTEREVENT_UP:begin
    fMouseAction:=pvgwmaNone;
    fCursor:=pvgcArrow;
   end;
   POINTEREVENT_MOTION:begin
    if fMouseAction=pvgwmaNone then begin
     fCursor:=pvgcArrow;
     if (pvgwfResizableNW in fWindowFlags) and
        (aPointerEvent.Position.x<Skin.fWindowResizeGripSize) and
        (aPointerEvent.Position.y<Skin.fWindowResizeGripSize) then begin
      fCursor:=pvgcNWSE;
     end else if (pvgwfResizableNE in fWindowFlags) and
                 (aPointerEvent.Position.x>(fSize.x-Skin.fWindowResizeGripSize)) and
                 (aPointerEvent.Position.y<Skin.fWindowResizeGripSize) then begin
      fCursor:=pvgcNESW;
     end else if (pvgwfResizableSW in fWindowFlags) and
                 (aPointerEvent.Position.x<Skin.fWindowResizeGripSize) and
                 (aPointerEvent.Position.y>(fSize.y-Skin.fWindowResizeGripSize)) then begin
      fCursor:=pvgcNESW;
     end else if (pvgwfResizableSE in fWindowFlags) and
                 (aPointerEvent.Position.x>(fSize.x-Skin.fWindowResizeGripSize)) and
                 (aPointerEvent.Position.y>(fSize.y-Skin.fWindowResizeGripSize)) then begin
      fCursor:=pvgcNWSE;
     end else if (pvgwfResizableN in fWindowFlags) and
                 (aPointerEvent.Position.y<Skin.fWindowResizeGripSize) then begin
      fCursor:=pvgcNS;
     end else if (pvgwfResizableS in fWindowFlags) and
                 (aPointerEvent.Position.y>(fSize.y-Skin.fWindowResizeGripSize)) then begin
      fCursor:=pvgcNS;
     end else if (pvgwfResizableW in fWindowFlags) and
                 (aPointerEvent.Position.x<Skin.fWindowResizeGripSize) then begin
      fCursor:=pvgcEW;
     end else if (pvgwfResizableE in fWindowFlags) and
                 (aPointerEvent.Position.x>(fSize.x-Skin.fWindowResizeGripSize)) then begin
      fCursor:=pvgcEW;
     end;
    end;
   end;
   POINTEREVENT_DRAG:begin
    MinimumSize:=TpvVector2.Create(Skin.fWindowMinimumWidth,Skin.fWindowMinimumHeight);
    case fMouseAction of
     pvgwmaMove:begin
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       ClampedRelativePosition:=Clamp(aPointerEvent.RelativePosition,-fPosition,(fParent as TpvGUIWidget).fSize-(fPosition+fSize));
      end else begin
       ClampedRelativePosition:=Maximum(aPointerEvent.RelativePosition,-fPosition);
      end;
      fPosition:=fPosition+ClampedRelativePosition;
      fCursor:=pvgcMove;
     end;
     pvgwmaSizeNW:begin
      NewSize:=Maximum(fSize-aPointerEvent.RelativePosition,MinimumSize);
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       ClampedRelativePosition:=Clamp(fPosition+(fSize-NewSize),TpvVector2.Null,(fParent as TpvGUIWidget).fSize-NewSize)-fPosition;
      end else begin
       ClampedRelativePosition:=Maximum(fPosition+(fSize-NewSize),TpvVector2.Null)-fPosition;
      end;
      fPosition:=fPosition+ClampedRelativePosition;
      fSize:=fSize-ClampedRelativePosition;
      fCursor:=pvgcNWSE;
     end;
     pvgwmaSizeNE:begin
      NewSize:=Maximum(fSize+TpvVector2.Create(aPointerEvent.RelativePosition.x,
                                               -aPointerEvent.RelativePosition.y),
                       MinimumSize);
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       ClampedRelativePosition.x:=Minimum(NewSize.x,(fParent as TpvGUIWidget).fSize.x-fPosition.x)-fSize.x;
       ClampedRelativePosition.y:=Clamp(fPosition.y+(fSize.y-NewSize.y),0.0,(fParent as TpvGUIWidget).fSize.y-NewSize.y)-fPosition.y;
      end else begin
       ClampedRelativePosition.x:=NewSize.x-fSize.x;
       ClampedRelativePosition.y:=Maximum(fPosition.y+(fSize.y-NewSize.y),0.0)-fPosition.y;
      end;
      fPosition.y:=fPosition.y+ClampedRelativePosition.y;
      fSize.x:=fSize.x+ClampedRelativePosition.x;
      fSize.y:=fSize.y-ClampedRelativePosition.y;
      fCursor:=pvgcNESW;
     end;
     pvgwmaSizeSW:begin
      NewSize:=Maximum(fSize+TpvVector2.Create(-aPointerEvent.RelativePosition.x,
                                               aPointerEvent.RelativePosition.y),
                       MinimumSize);
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       ClampedRelativePosition.x:=Clamp(fPosition.x+(fSize.x-NewSize.x),0.0,(fParent as TpvGUIWidget).fSize.x-NewSize.x)-fPosition.x;
       ClampedRelativePosition.y:=Minimum(NewSize.y,(fParent as TpvGUIWidget).fSize.y-fPosition.y)-fSize.y;
      end else begin
       ClampedRelativePosition.x:=Maximum(fPosition.x+(fSize.x-NewSize.x),0.0)-fPosition.x;
       ClampedRelativePosition.y:=NewSize.y-fSize.y;
      end;
      fPosition.x:=fPosition.x+ClampedRelativePosition.x;
      fSize.x:=fSize.x-ClampedRelativePosition.x;
      fSize.y:=fSize.y+ClampedRelativePosition.y;
      fCursor:=pvgcNESW;
     end;
     pvgwmaSizeSE:begin
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       fSize:=Clamp(fSize+aPointerEvent.RelativePosition,MinimumSize,(fParent as TpvGUIWidget).fSize-fPosition);
      end else begin
       fSize:=Maximum(fSize+aPointerEvent.RelativePosition,MinimumSize);
      end;
      fCursor:=pvgcNWSE;
     end;
     pvgwmaSizeN:begin
      NewSize.y:=Maximum(fSize.y-aPointerEvent.RelativePosition.y,MinimumSize.y);
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       ClampedRelativePosition.y:=Clamp(fPosition.y+(fSize.y-NewSize.y),0.0,(fParent as TpvGUIWidget).fSize.y-NewSize.y)-fPosition.y;
      end else begin
       ClampedRelativePosition.y:=Maximum(fPosition.y+(fSize.y-NewSize.y),0.0)-fPosition.y;
      end;
      fPosition.y:=fPosition.y+ClampedRelativePosition.y;
      fSize.y:=fSize.y-ClampedRelativePosition.y;
      fCursor:=pvgcNS;
     end;
     pvgwmaSizeS:begin
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       fSize.y:=Clamp(fSize.y+aPointerEvent.RelativePosition.y,MinimumSize.y,(fParent as TpvGUIWidget).fSize.y-fPosition.y);
      end else begin
       fSize.y:=Maximum(fSize.y+aPointerEvent.RelativePosition.y,MinimumSize.y);
      end;
      fCursor:=pvgcNS;
     end;
     pvgwmaSizeW:begin
      NewSize.x:=Maximum(fSize.x-aPointerEvent.RelativePosition.x,MinimumSize.x);
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       ClampedRelativePosition.x:=Clamp(fPosition.x+(fSize.x-NewSize.x),0.0,(fParent as TpvGUIWidget).fSize.x-NewSize.x)-fPosition.x;
      end else begin
       ClampedRelativePosition.x:=Maximum(fPosition.x+(fSize.x-NewSize.x),0.0)-fPosition.x;
      end;
      fPosition.x:=fPosition.x+ClampedRelativePosition.x;
      fSize.x:=fSize.x-ClampedRelativePosition.x;
      fCursor:=pvgcEW;
     end;
     pvgwmaSizeE:begin
      if assigned(fParent) and (fParent is TpvGUIWidget) then begin
       fSize.x:=Clamp(fSize.x+aPointerEvent.RelativePosition.x,MinimumSize.x,(fParent as TpvGUIWidget).fSize.x-fPosition.x);
      end else begin
       fSize.x:=Maximum(fSize.x+aPointerEvent.RelativePosition.x,MinimumSize.x);
      end;
      fCursor:=pvgcEW;
     end;
     else begin
      fCursor:=pvgcArrow;
     end;
    end;
    if assigned(fParent) and (fParent is TpvGUIWidget) then begin
     fSize:=Clamp(fSize,MinimumSize,(fParent as TpvGUIWidget).fSize-fPosition);
     fPosition:=Clamp(fPosition,TpvVector2.Null,(fParent as TpvGUIWidget).fSize-fSize);
    end else begin
     fSize:=Maximum(fSize,MinimumSize);
     fPosition:=Maximum(fPosition,TpvVector2.Null);
    end;
   end;
  end;
 end;
 result:=true;
end;

function TpvGUIWindow.Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean;
begin
 inherited Scrolled(aPosition,aRelativeAmount);
 result:=true;
end;

procedure TpvGUIWindow.Update;
begin
 Skin.DrawWindow(fCanvas,self);
 inherited Update;
end;

procedure TpvGUIWindow.Draw;
begin
 inherited Draw;
end;

constructor TpvGUILabel.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fCaption:='Label';
end;

destructor TpvGUILabel.Destroy;
begin
 inherited Destroy;
end;

function TpvGUILabel.GetPreferredSize:TpvVector2;
begin
 result:=Maximum(inherited GetPreferredSize,
                 Skin.fSansFont.TextSize(fCaption,FontSize)+TpvVector2.Create(0.0,0.0));
end;

function TpvGUILabel.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
begin
 result:=inherited KeyEvent(aKeyEvent);
end;

function TpvGUILabel.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
begin
 result:=inherited PointerEvent(aPointerEvent);
end;

function TpvGUILabel.Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean;
begin
 result:=inherited Scrolled(aPosition,aRelativeAmount);
end;

procedure TpvGUILabel.Update;
begin
 Skin.DrawLabel(fCanvas,self);
 inherited Update;
end;

procedure TpvGUILabel.Draw;
begin
 inherited Draw;
end;

constructor TpvGUIButton.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fButtonFlags:=[pvgbfNormalButton];
 fCaption:='Button';
 fOnClick:=nil;
end;

destructor TpvGUIButton.Destroy;
begin
 inherited Destroy;
end;

function TpvGUIButton.GetDown:boolean;
begin
 result:=pvgbfDown in fButtonFlags;
end;

procedure TpvGUIButton.SetDown(const aDown:boolean);
begin
 if aDown then begin
  Include(fButtonFlags,pvgbfDown);
 end else begin
  Exclude(fButtonFlags,pvgbfDown);
 end;
end;

function TpvGUIButton.GetPreferredSize:TpvVector2;
begin
 result:=Maximum(inherited GetPreferredSize,
                 Skin.fSansFont.TextSize(fCaption,FontSize)+TpvVector2.Create(16.0,8.0));
end;

function TpvGUIButton.KeyEvent(const aKeyEvent:TpvApplicationInputKeyEvent):boolean;
begin
 result:=inherited KeyEvent(aKeyEvent);
end;

function TpvGUIButton.PointerEvent(const aPointerEvent:TpvApplicationInputPointerEvent):boolean;
begin
 result:=inherited PointerEvent(aPointerEvent);
 if Enabled and (aPointerEvent.Button=BUTTON_LEFT) and not result then begin
  case aPointerEvent.PointerEventType of
   POINTEREVENT_DOWN:begin
    Down:=true;
   end;
   POINTEREVENT_UP:begin
    if assigned(fOnClick) and Contains(aPointerEvent.Position) then begin
     fOnClick(self);
    end;
    Down:=false;
   end;
   POINTEREVENT_MOTION:begin
   end;
   POINTEREVENT_DRAG:begin
   end;
  end;
 end;
end;

function TpvGUIButton.Scrolled(const aPosition,aRelativeAmount:TpvVector2):boolean;
begin
 result:=inherited Scrolled(aPosition,aRelativeAmount);
end;

procedure TpvGUIButton.Update;
begin
 Skin.DrawButton(fCanvas,self);
 inherited Update;
end;

procedure TpvGUIButton.Draw;
begin
 inherited Draw;
end;

constructor TpvGUIRadioButton.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fButtonFlags:=(fButtonFlags-[pvgbfNormalButton])+[pvgbfRadioButton];
end;

constructor TpvGUIToggleButton.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fButtonFlags:=(fButtonFlags-[pvgbfNormalButton])+[pvgbfToggleButton];
end;

constructor TpvGUIPopupButton.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fButtonFlags:=(fButtonFlags-[pvgbfNormalButton])+[pvgbfToggleButton,pvgbfPopupButton];
end;

constructor TpvGUIToolButton.Create(const aParent:TpvGUIObject);
begin
 inherited Create(aParent);
 fButtonFlags:=(fButtonFlags-[pvgbfNormalButton])+[pvgbfRadioButton,pvgbfToggleButton];
end;

end.
