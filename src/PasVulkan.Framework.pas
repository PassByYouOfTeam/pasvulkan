(******************************************************************************
 *                                 PasVulkan                                  *
 ******************************************************************************
 *                        Version 2017-09-28-04-36-0000                       *
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
unit PasVulkan.Framework;
{$i PasVulkan.inc}
{$ifndef fpc}
 {$ifdef conditionalexpressions}
  {$if CompilerVersion>=24.0}
   {$legacyifend on}
  {$ifend}
 {$endif}
{$endif}

interface

uses {$if defined(Windows)}
      Windows,
     {$elseif defined(Unix)}
      BaseUnix,UnixType,dl,
     {$ifend}
     {$if defined(XLIB) and defined(VulkanUseXLIBUnits)}x,xlib,{$ifend}
     {$if defined(XCB) and defined(VulkanUseXCBUnits)}xcb,{$ifend}
     {$if defined(Mir) and defined(VulkanUseMirUnits)}Mir,{$ifend}
     {$if defined(Wayland) and defined(VulkanUseWaylandUnits)}Wayland,{$ifend}
     {$if defined(Android) and defined(VulkanUseAndroidUnits)}Android,{$ifend}
     SysUtils,Classes,SyncObjs,Math,
     PasMP,
     PUCU,
     Vulkan,
     PasVulkan.Types,
     PasVulkan.Math,
     PasVulkan.Collections,
     PasVulkan.XML,
     PasVulkan.TrueTypeFont,
     PasVulkan.Image.BMP,
     PasVulkan.Image.JPEG,
     PasVulkan.Image.PNG,
     PasVulkan.Image.TGA;

var VulkanMinimumMemoryChunkSize:TVkDeviceSize=TVkDeviceSize(1) shl 24; // 16 MB minimum memory chunk size

    VulkanSmallMaximumHeapSize:TVkDeviceSize=TVkDeviceSize(1) shl 31; // 2048 MB small maximum heap size as threshold

    VulkanDefaultAndroidHeapChunkSize:TVkDeviceSize=TVkDeviceSize(1) shl 24; // 16 MB memory chunk size at heaps on Android-devices

    VulkanDefaultSmallHeapChunkSize:TVkDeviceSize=TVkDeviceSize(1) shl 25; // 32 MB memory chunk size at small-sized heaps

    VulkanDefaultLargeHeapChunkSize:TVkDeviceSize=TVkDeviceSize(1) shl 27; // 128 MB memory chunk size at large-sized heaps

const VULKAN_SPRITEATLASTEXTURE_WIDTH=2048;
      VULKAN_SPRITEATLASTEXTURE_HEIGHT=2048;

      VulkanFontDistanceFieldSpreadValue=4;

type EpvVulkanException=class(Exception);

     EpvVulkanMemoryAllocationException=class(EpvVulkanException);

     EpvVulkanTextureException=class(EpvVulkanException);

     EpvVulkanSurfaceException=class(EpvVulkanException);

     EpvVulkanPipelineCacheException=class(EpvVulkanException);

     EpvVulkanResultException=class(EpvVulkanException)
      private
       fResultCode:TVkResult;
      public
       constructor Create(const aResultCode:TVkResult);
       destructor Destroy; override;
      published
       property ResultCode:TVkResult read fResultCode;
     end;

     PpvVulkanUUID=^TpvVulkanUUID;
     TpvVulkanUUID=array[0..VK_UUID_SIZE-1] of TpvUInt8;

     PpvVulkanBytes=^TpvVulkanBytes;
     TpvVulkanBytes=array[0..65535] of TpvUInt8;

     TpvVulkanFormatSizeFlag=
      (
       vfsfPacked,
       vfsfCompressed,
       vfsfPalettized,
       vfsfDepth,
       vfsfStencil
      );

     TpvVulkanFormatSizeFlags=set of TpvVulkanFormatSizeFlag;

     PpvVulkanFormatSize=^TpvVulkanFormatSize;
     TpvVulkanFormatSize=record
      Flags:TpvVulkanFormatSizeFlags;
      PaletteSizeInBits:TpvUInt32;
      BlockSizeInBits:TpvUInt32;
      BlockWidth:TpvUInt32; // in texels
      BlockHeight:TpvUInt32; // in texels
      BlockDepth:TpvUInt32; // in texels
     end;

     TpvVulkanObject=class(TpvReferenceCountedObject);

     PpvVulkanRawByteChar=PAnsiChar;
     TpvVulkanRawByteChar=AnsiChar;

     PpvVulkanCharString=^TpvVulkanCharString;
     TpvVulkanCharString=TVkCharString;

     TpvVulkanCharStringArray=array of TpvVulkanCharString;
     TVkUInt8Array=array of TVkUInt8;
     TVkInt32Array=array of TVkInt32;
     TVkUInt32Array=array of TVkUInt32;
     TVkFloatArray=array of TpvFloat;
     TVkLayerPropertiesArray=array of TVkLayerProperties;
     TVkExtensionPropertiesArray=array of TVkExtensionProperties;
     TVkLayerExtensionPropertiesArray=array of array of TVkExtensionProperties;
     TPVkCharArray=array of PVkChar;
     TVkPhysicalDeviceArray=array of TVkPhysicalDevice;
     TVkQueueFamilyPropertiesArray=array of TVkQueueFamilyProperties;
     TVkSparseImageFormatPropertiesArray=array of TVkSparseImageFormatProperties;
     TVkSurfaceFormatKHRArray=array of TVkSurfaceFormatKHR;
     TVkPresentModeKHRArray=array of TVkPresentModeKHR;
     TVkDisplayPropertiesKHRArray=array of TVkDisplayPropertiesKHR;
     TVkDisplayPlanePropertiesKHRArray=array of TVkDisplayPlanePropertiesKHR;
     TVkDisplayKHRArray=array of TVkDisplayKHR;
     TVkDisplayModePropertiesKHRArray=array of TVkDisplayModePropertiesKHR;
     TVkDeviceQueueCreateInfoArray=array of TVkDeviceQueueCreateInfo;
     TVkImageArray=array of TVkImage;
     TVkSamplerArray=array of TVkSampler;
     TVkCommandBufferArray=array of TVkCommandBuffer;
     TVkDescriptorSetLayoutBindingArray=array of TVkDescriptorSetLayoutBinding;
     TVkDescriptorSetLayoutArray=array of TVkDescriptorSetLayout;
     TVkPushConstantRangeArray=array of TVkPushConstantRange;
     TVkPipelineShaderStageCreateInfoArray=array of TVkPipelineShaderStageCreateInfo;
     TVkPipelineVertexInputStateCreateInfoArray=array of TVkPipelineVertexInputStateCreateInfo;
     TVkAttachmentDescriptionArray=array of TVkAttachmentDescription;
     TVkSubpassDescriptionArray=array of TVkSubpassDescription;
     TVkSubpassDependencyArray=array of TVkSubpassDependency;
     TVkAttachmentReferenceArray=array of TVkAttachmentReference;
     TVkMemoryBarrierArray=array of TVkMemoryBarrier;
     TVkBufferMemoryBarrierArray=array of TVkBufferMemoryBarrier;
     TVkImageMemoryBarrierArray=array of TVkImageMemoryBarrier;
     TVkViewportArray=array of TVkViewport;
     TVkRect2DArray=array of TVkRect2D;
     TVkSampleMaskArray=array of TVkSampleMask;
     TVkVertexInputBindingDescriptionArray=array of TVkVertexInputBindingDescription;
     TVkVertexInputAttributeDescriptionArray=array of TVkVertexInputAttributeDescription;
     TVkPipelineColorBlendAttachmentStateArray=array of TVkPipelineColorBlendAttachmentState;
     TVkDynamicStateArray=array of TVkDynamicState;
     TVkDescriptorPoolSizeArray=array of TVkDescriptorPoolSize;
     TVkDescriptorSetArray=array of TVkDescriptorSet;
     TVkDescriptorImageInfoArray=array of TVkDescriptorImageInfo;
     TVkDescriptorBufferInfoArray=array of TVkDescriptorBufferInfo;
     TVkClearValueArray=array of TVkClearValue;
     TVkResultArray=array of TVkResult;
     TVkCopyDescriptorSetArray=array of TVkCopyDescriptorSet;
     TVkWriteDescriptorSetArray=array of TVkWriteDescriptorSet;
     TVkSpecializationMapEntryArray=array of TVkSpecializationMapEntry;
     TVkPipelineCacheArray=array of TVkPipelineCache;
     TVkBufferImageCopyArray=array of TVkBufferImageCopy;

     TpvVulkanBaseList=class(TpvVulkanObject)
      private
       fItemSize:TVkSizeInt;
       fCount:TVkSizeInt;
       fAllocated:TVkSizeInt;
       fMemory:TpvPointer;
       procedure SetCount(const NewCount:TVkSizeInt);
       function GetItem(const Index:TVkSizeInt):TpvPointer;
      protected
       procedure InitializeItem(var Item); virtual;
       procedure FinalizeItem(var Item); virtual;
       procedure CopyItem(const Source;var Destination); virtual;
       procedure ExchangeItem(var Source,Destination); virtual;
       function CompareItem(const Source,Destination):TpvInt32; virtual;
      public
       constructor Create(const aItemSize:TVkSizeInt);
       destructor Destroy; override;
       procedure Clear; virtual;
       procedure FillWith(const SourceData;const SourceCount:TVkSizeInt); virtual;
       function Add(const Item):TVkSizeInt;
       function Find(const Item):TVkSizeInt;
       procedure Insert(const Index:TVkSizeInt;const Item);
       procedure Delete(const Index:TVkSizeInt);
       procedure Remove(const Item);
       procedure Exchange(const Index,WithIndex:TVkSizeInt);
       property Count:TVkSizeInt read fCount write SetCount;
       property Allocated:TVkSizeInt read fAllocated;
       property Memory:TpvPointer read fMemory;
       property ItemPointers[const Index:TVkSizeInt]:TpvPointer read GetItem; default;
     end;

     TpvVulkanObjectList=class(TpvVulkanBaseList)
      private
       fOwnObjects:boolean;
       function GetItem(const Index:TVkSizeInt):TpvVulkanObject;
       procedure SetItem(const Index:TVkSizeInt;const Item:TpvVulkanObject);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear; override;
       function Add(const Item:TpvVulkanObject):TVkSizeInt; reintroduce;
       function Find(const Item:TpvVulkanObject):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TpvVulkanObject); reintroduce;
       procedure Remove(const Item:TpvVulkanObject); reintroduce;
       property Items[const Index:TVkSizeInt]:TpvVulkanObject read GetItem write SetItem; default;
       property OwnObjects:boolean read fOwnObjects write fOwnObjects;
     end;

     TVkUInt32List=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TpvUInt32;
       procedure SetItem(const Index:TVkSizeInt;const Item:TpvUInt32);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TpvUInt32):TVkSizeInt; reintroduce;
       function Find(const Item:TpvUInt32):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TpvUInt32); reintroduce;
       procedure Remove(const Item:TpvUInt32); reintroduce;
       property Items[const Index:TVkSizeInt]:TpvUInt32 read GetItem write SetItem; default;
     end;

     TVkFloatList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TpvFloat;
       procedure SetItem(const Index:TVkSizeInt;const Item:TpvFloat);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TpvFloat):TVkSizeInt; reintroduce;
       function Find(const Item:TpvFloat):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TpvFloat); reintroduce;
       procedure Remove(const Item:TpvFloat); reintroduce;
       property Items[const Index:TVkSizeInt]:TpvFloat read GetItem write SetItem; default;
     end;

     TVkImageViewList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkImageView;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkImageView);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkImageView):TVkSizeInt; reintroduce;
       function Find(const Item:TVkImageView):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkImageView); reintroduce;
       procedure Remove(const Item:TVkImageView); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkImageView read GetItem write SetItem; default;
     end;

     TVkSamplerList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkSampler;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkSampler);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkSampler):TVkSizeInt; reintroduce;
       function Find(const Item:TVkSampler):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkSampler); reintroduce;
       procedure Remove(const Item:TVkSampler); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkSampler read GetItem write SetItem; default;
     end;

     TVkDescriptorSetLayoutList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkDescriptorSetLayout;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkDescriptorSetLayout):TVkSizeInt; reintroduce;
       function Find(const Item:TVkDescriptorSetLayout):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout); reintroduce;
       procedure Remove(const Item:TVkDescriptorSetLayout); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkDescriptorSetLayout read GetItem write SetItem; default;
     end;

     TVkSampleMaskList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkSampleMask;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkSampleMask);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkSampleMask):TVkSizeInt; reintroduce;
       function Find(const Item:TVkSampleMask):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkSampleMask); reintroduce;
       procedure Remove(const Item:TVkSampleMask); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkSampleMask read GetItem write SetItem; default;
     end;

     TVkDynamicStateList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkDynamicState;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkDynamicState);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkDynamicState):TVkSizeInt; reintroduce;
       function Find(const Item:TVkDynamicState):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkDynamicState); reintroduce;
       procedure Remove(const Item:TVkDynamicState); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkDynamicState read GetItem write SetItem; default;
     end;

     TVkBufferViewList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkBufferView;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkBufferView);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkBufferView):TVkSizeInt; reintroduce;
       function Find(const Item:TVkBufferView):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkBufferView); reintroduce;
       procedure Remove(const Item:TVkBufferView); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkBufferView read GetItem write SetItem; default;
     end;

     TVkClearValueList=class(TpvVulkanBaseList)
      private
       function GetItem(const Index:TVkSizeInt):TVkClearValue;
       procedure SetItem(const Index:TVkSizeInt;const Item:TVkClearValue);
      protected
       procedure InitializeItem(var Item); override;
       procedure FinalizeItem(var Item); override;
       procedure CopyItem(const Source;var Destination); override;
       procedure ExchangeItem(var Source,Destination); override;
       function CompareItem(const Source,Destination):TpvInt32; override;
      public
       constructor Create;
       destructor Destroy; override;
       function Add(const Item:TVkClearValue):TVkSizeInt; reintroduce;
       function Find(const Item:TVkClearValue):TVkSizeInt; reintroduce;
       procedure Insert(const Index:TVkSizeInt;const Item:TVkClearValue); reintroduce;
       procedure Remove(const Item:TVkClearValue); reintroduce;
       property Items[const Index:TVkSizeInt]:TVkClearValue read GetItem write SetItem; default;
     end;

     TpvVulkanAllocationManager=class(TpvVulkanObject)
      private
       fAllocationCallbacks:TVkAllocationCallbacks;
      protected
       function AllocationCallback(const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid; virtual;
       function ReallocationCallback(const Original:PVkVoid;const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid; virtual;
       procedure FreeCallback(const Memory:PVkVoid); virtual;
       procedure InternalAllocationCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
       procedure InternalFreeCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
      public
       constructor Create;
       destructor Destroy; override;
       property AllocationCallbacks:TVkAllocationCallbacks read fAllocationCallbacks;
     end;

     PpvVulkanAvailableLayer=^TpvVulkanAvailableLayer;
     TpvVulkanAvailableLayer=record
      LayerName:TpvVulkanCharString;
      SpecVersion:TpvUInt32;
      ImplementationVersion:TpvUInt32;
      Description:TpvVulkanCharString;
     end;

     TpvVulkanAvailableLayers=array of TpvVulkanAvailableLayer;

     PpvVulkanAvailableExtension=^TpvVulkanAvailableExtension;
     TpvVulkanAvailableExtension=record
      LayerIndex:TpvUInt32;
      ExtensionName:TpvVulkanCharString;
      SpecVersion:TpvUInt32;
     end;

     TpvVulkanAvailableExtensions=array of TpvVulkanAvailableExtension;

     TpvVulkanInstance=class;

     TpvVulkanPhysicalDevice=class;

     TpvVulkanPhysicalDeviceList=class;

     TpvVulkanInstanceDebugReportCallback=function(const flags:TVkDebugReportFlagsEXT;const objectType:TVkDebugReportObjectTypeEXT;const object_:TVkUInt64;const location:TVkSize;messageCode:TpvInt32;const aLayerPrefix,aMessage:string):TVkBool32 of object;

     TpvVulkanInstance=class(TpvVulkanObject)
      private    
       fVulkan:TVulkan;
       fApplicationInfo:TVkApplicationInfo;
       fApplicationName:TpvVulkanCharString;
       fEngineName:TpvVulkanCharString;
       fValidation:longbool;
       fAllocationManager:TpvVulkanAllocationManager;
       fAllocationCallbacks:PVkAllocationCallbacks;
       fAvailableLayers:TpvVulkanAvailableLayers;
       fAvailableExtensions:TpvVulkanAvailableExtensions;
       fAvailableLayerNames:TStringList;
       fAvailableExtensionNames:TStringList;
       fEnabledLayerNames:TStringList;
       fEnabledExtensionNames:TStringList;
       fEnabledLayerNameStrings:array of TpvVulkanCharString;
       fEnabledExtensionNameStrings:array of TpvVulkanCharString;
       fRawEnabledLayerNameStrings:array of PVkChar;
       fRawEnabledExtensionNameStrings:array of PVkChar;
       fInstanceHandle:TVkInstance;
       fInstanceVulkan:TVulkan;
       fPhysicalDevices:TpvVulkanPhysicalDeviceList;
       fNeedToEnumeratePhysicalDevices:boolean;
       fDebugReportCallbackCreateInfoEXT:TVkDebugReportCallbackCreateInfoEXT;
       fDebugReportCallbackEXT:TVkDebugReportCallbackEXT;
       fOnInstanceDebugReportCallback:TpvVulkanInstanceDebugReportCallback;
       procedure SetApplicationInfo(const NewApplicationInfo:TVkApplicationInfo);
       function GetApplicationName:TpvVulkanCharString;
       procedure SetApplicationName(const NewApplicationName:TpvVulkanCharString);
       function GetApplicationVersion:TpvUInt32;
       procedure SetApplicationVersion(const NewApplicationVersion:TpvUInt32);
       function GetEngineName:TpvVulkanCharString;
       procedure SetEngineName(const NewEngineName:TpvVulkanCharString);
       function GetEngineVersion:TpvUInt32;
       procedure SetEngineVersion(const NewEngineVersion:TpvUInt32);
       function GetAPIVersion:TpvUInt32;
       procedure SetAPIVersion(const NewAPIVersion:TpvUInt32);
       procedure EnumeratePhysicalDevices;
      protected
       function DebugReportCallback(const flags:TVkDebugReportFlagsEXT;const objectType:TVkDebugReportObjectTypeEXT;const object_:TVkUInt64;const location:TVkSize;messageCode:TpvInt32;const aLayerPrefix:TpvVulkanCharString;const aMessage:TpvVulkanCharString):TVkBool32; virtual;
      public
       constructor Create(const aApplicationName:TpvVulkanCharString='Vulkan application';
                          const aApplicationVersion:TpvUInt32=1;
                          const aEngineName:TpvVulkanCharString='Vulkan engine';
                          const aEngineVersion:TpvUInt32=1;
                          const pAPIVersion:TpvUInt32=VK_API_VERSION_1_0;
                          const aValidation:boolean=false;
                          const aAllocationManager:TpvVulkanAllocationManager=nil);
       destructor Destroy; override;
       procedure Initialize;
       procedure InstallDebugReportCallback;
       property ApplicationInfo:TVkApplicationInfo read fApplicationInfo write SetApplicationInfo;
      published
       property ApplicationName:TpvVulkanCharString read GetApplicationName write SetApplicationName;
       property ApplicationVersion:TpvUInt32 read GetApplicationVersion write SetApplicationVersion;
       property EngineName:TpvVulkanCharString read GetEngineName write SetEngineName;
       property EngineVersion:TpvUInt32 read GetEngineVersion write SetEngineVersion;
       property APIVersion:TpvUInt32 read GetAPIVersion write SetAPIVersion;
       property Validation:longbool read fValidation write fValidation;
       property AvailableLayers:TpvVulkanAvailableLayers read fAvailableLayers;
       property AvailableExtensions:TpvVulkanAvailableExtensions read fAvailableExtensions;
       property AvailableLayerNames:TStringList read fAvailableLayerNames;
       property AvailableExtensionNames:TStringList read fAvailableExtensionNames;
       property EnabledLayerNames:TStringList read fEnabledLayerNames;
       property EnabledExtensionNames:TStringList read fEnabledExtensionNames;
       property Handle:TVkInstance read fInstanceHandle;
       property Commands:TVulkan read fInstanceVulkan;
       property PhysicalDevices:TpvVulkanPhysicalDeviceList read fPhysicalDevices;
       property OnInstanceDebugReportCallback:TpvVulkanInstanceDebugReportCallback read fOnInstanceDebugReportCallback write fOnInstanceDebugReportCallback;
     end;

     TpvVulkanSurface=class;

     TpvVulkanPhysicalDevice=class(TpvVulkanObject)
      private
       fInstance:TpvVulkanInstance;
       fPhysicalDeviceHandle:TVkPhysicalDevice;
       fDeviceName:TpvVulkanCharString;
       fProperties:TVkPhysicalDeviceProperties;
       fMemoryProperties:TVkPhysicalDeviceMemoryProperties;
       fFeatures:TVkPhysicalDeviceFeatures;
       fQueueFamilyProperties:TVkQueueFamilyPropertiesArray;
       fAvailableLayers:TpvVulkanAvailableLayers;
       fAvailableExtensions:TpvVulkanAvailableExtensions;
       fAvailableLayerNames:TStringList;
       fAvailableExtensionNames:TStringList;
      public
       constructor Create(const aInstance:TpvVulkanInstance;const aPhysicalDevice:TVkPhysicalDevice);
       destructor Destroy; override;
       function HasQueueSupportForSparseBindings(const aQueueFamilyIndex:TpvUInt32):boolean;
       function GetFormatProperties(const aFormat:TVkFormat):TVkFormatProperties;
       function GetImageFormatProperties(const aFormat:TVkFormat;
                                         const aType:TVkImageType;
                                         const aTiling:TVkImageTiling;
                                         const aUsageFlags:TVkImageUsageFlags;
                                         const aCreateFlags:TVkImageCreateFlags):TVkImageFormatProperties;
       function GetSparseImageFormatProperties(const aFormat:TVkFormat;
                                               const aType:TVkImageType;
                                               const aSamples:TVkSampleCountFlagBits;
                                               const aUsageFlags:TVkImageUsageFlags;
                                               const aTiling:TVkImageTiling):TVkSparseImageFormatPropertiesArray;
       function GetSurfaceSupport(const aQueueFamilyIndex:TpvUInt32;const aSurface:TpvVulkanSurface):boolean;
       function GetSurfaceCapabilities(const aSurface:TpvVulkanSurface):TVkSurfaceCapabilitiesKHR;
       function GetSurfaceFormats(const aSurface:TpvVulkanSurface):TVkSurfaceFormatKHRArray;
       function GetSurfacePresentModes(const aSurface:TpvVulkanSurface):TVkPresentModeKHRArray;
       function GetDisplayProperties:TVkDisplayPropertiesKHRArray;
       function GetDisplayPlaneProperties:TVkDisplayPlanePropertiesKHRArray;
       function GetDisplayPlaneSupportedDisplays(const aPlaneIndex:TpvUInt32):TVkDisplayKHRArray;
       function GetDisplayModeProperties(const aDisplay:TVkDisplayKHR):TVkDisplayModePropertiesKHRArray;
       function GetMemoryType(const aTypeBits:TpvUInt32;const aProperties:TVkFlags):TpvUInt32;
       function GetBestSupportedDepthFormat(const aWithStencil:boolean):TVkFormat;
       function GetQueueNodeIndex(const aSurface:TpvVulkanSurface;const aQueueFlagBits:TVkQueueFlagBits):TpvInt32;
       function GetSurfaceFormat(const aSurface:TpvVulkanSurface;const aSRGB:boolean=false):TVkSurfaceFormatKHR;
       property Properties:TVkPhysicalDeviceProperties read fProperties;
       property MemoryProperties:TVkPhysicalDeviceMemoryProperties read fMemoryProperties;
       property Features:TVkPhysicalDeviceFeatures read fFeatures;
      published
       property Handle:TVkPhysicalDevice read fPhysicalDeviceHandle;
       property DeviceName:TpvVulkanCharString read fDeviceName;
       property QueueFamilyProperties:TVkQueueFamilyPropertiesArray read fQueueFamilyProperties;
       property AvailableLayers:TpvVulkanAvailableLayers read fAvailableLayers;
       property AvailableExtensions:TpvVulkanAvailableExtensions read fAvailableExtensions;
       property AvailableLayerNames:TStringList read fAvailableLayerNames;
       property AvailableExtensionNames:TStringList read fAvailableExtensionNames;
     end;

     TpvVulkanPhysicalDeviceList=class(TpvVulkanObjectList)
      private
       function GetItem(const Index:TVkSizeInt):TpvVulkanPhysicalDevice;
       procedure SetItem(const Index:TVkSizeInt;const Item:TpvVulkanPhysicalDevice);
      public
       property Items[const Index:TVkSizeInt]:TpvVulkanPhysicalDevice read GetItem write SetItem; default;
     end;

     PpvVulkanSurfacePlatform=^TpvVulkanSurfacePlatform;
     TpvVulkanSurfacePlatform=
      (
       vspUnknown,
       vspAndroid,
       vspMir,
       vspWayland,
       vspWin32,
       vspXCB,
       vspXLIB,
       vspMolkenVK_IOS,
       vspMolkenVK_MacOS
      );

     PpvVulkanSurfaceCreateInfo=^TpvVulkanSurfaceCreateInfo;
     TpvVulkanSurfaceCreateInfo=record
      case TpvVulkanSurfacePlatform of
       vspUnknown:(
        sType:TVkStructureType; //< Must be VK_STRUCTURE_TYPE_*_SURFACE_CREATE_INFO_KHR
        aNext:PVkVoid; //< TpvPointer to next structure
        flags:TVkFlags; //< Reserved
       );
{$if defined(Android) and defined(Unix)}
       vspAndroid:(
        Android:TVkAndroidSurfaceCreateInfoKHR;
       );
{$ifend}
{$if defined(Mir) and defined(Unix)}
       vspMir:(
        Mir:TVkMirSurfaceCreateInfoKHR;
       );
{$ifend}
{$if defined(Wayland) and defined(Unix)}
       vspWayland:(
        Wayland:TVkWaylandSurfaceCreateInfoKHR;
       );
{$ifend}
{$if defined(Windows)}
       vspWin32:(
        Win32:TVkWin32SurfaceCreateInfoKHR;
       );
{$ifend}
{$if defined(XCB) and defined(Unix)}
       vspXCB:(
        XCB:TVkXCBSurfaceCreateInfoKHR;
       );
{$ifend}
{$if defined(XLIB) and defined(Unix)}
       vspXLIB:(
        XLIB:TVkXLIBSurfaceCreateInfoKHR;
       );
{$ifend}
{$if defined(MoltenVK_IOS) and defined(Darwin)}
       vspMolkenVK_IOS:(
        MolkenVK_IOS:TVkIOSSurfaceCreateInfoMVK;
       );
{$ifend}
{$if defined(MoltenVK_MacOS) and defined(Darwin)}
       vspMolkenVK_MacOS:(
        MolkenVK_MacOS:TVkMacOSSurfaceCreateInfoMVK;
       );
{$ifend}
     end;

     TpvVulkanSurface=class(TpvVulkanObject)
      private
       fInstance:TpvVulkanInstance;
       fSurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
       fSurfaceHandle:TVkSurfaceKHR;
      protected
      public
       constructor Create(const aInstance:TpvVulkanInstance;const aSurfaceCreateInfo:TpvVulkanSurfaceCreateInfo);
       constructor CreateHandle(const aInstance:TpvVulkanInstance;const aSurfaceHandle:TVkSurfaceKHR);
{$if defined(Android)}
       constructor CreateAndroid(const aInstance:TpvVulkanInstance;const aWindow:PVkAndroidANativeWindow);
{$ifend}
{$if defined(Mir) and defined(Unix)}
       constructor CreateMir(const aInstance:TpvVulkanInstance;const aConnection:PVkMirConnection;const aSurface:PVkMirSurface);
{$ifend}
{$if defined(Wayland) and defined(Unix)}
       constructor CreateWayland(const aInstance:TpvVulkanInstance;const aDisplay:PVkWaylandDisplay;const aSurface:PVkWaylandSurface);
{$ifend}
{$if defined(Windows)}
       constructor CreateWin32(const aInstance:TpvVulkanInstance;const aInstanceHandle,aWindowHandle:Windows.THandle);
{$ifend}
{$if defined(XCB) and defined(Unix)}
       constructor CreateXCB(const aInstance:TpvVulkanInstance;const aConnection:PVkXCBConnection;const aWindow:TVkXCBWindow);
{$ifend}
{$if defined(XLIB) and defined(Unix)}
       constructor CreateXLIB(const aInstance:TpvVulkanInstance;const aDisplay:PVkXLIBDisplay;const aWindow:TVkXLIBWindow);
{$ifend}
{$if defined(MoltenVK_IOS) and defined(Darwin)}
       constructor CreateMoltenVK_IOS(const aInstance:TpvVulkanInstance;const aView:PVkVoid);
{$ifend}
{$if defined(MoltenVK_MacOS) and defined(Darwin)}
       constructor CreateMoltenVK_MacOS(const aInstance:TpvVulkanInstance;const aView:PVkVoid);
{$ifend}
       destructor Destroy; override;
      published
       property Handle:TVkSurfaceKHR read fSurfaceHandle;
     end;

     TpvVulkanDeviceQueueCreateInfo=class;

     TpvVulkanDeviceQueueCreateInfoList=class;

     TpvVulkanDeviceMemoryManager=class;

     TpvVulkanQueue=class;

     TpvVulkanQueues=array of TpvVulkanQueue;

     TpvVulkanDevice=class(TpvVulkanObject)
      private
       fInstance:TpvVulkanInstance;
       fPhysicalDevice:TpvVulkanPhysicalDevice;
       fSurface:TpvVulkanSurface;
       fDeviceQueueCreateInfoList:TpvVulkanDeviceQueueCreateInfoList;
       fDeviceQueueCreateInfos:TVkDeviceQueueCreateInfoArray;
       fEnabledLayerNames:TStringList;
       fEnabledExtensionNames:TStringList;
       fEnabledLayerNameStrings:array of TpvVulkanCharString;
       fEnabledExtensionNameStrings:array of TpvVulkanCharString;
       fRawEnabledLayerNameStrings:array of PVkChar;
       fRawEnabledExtensionNameStrings:array of PVkChar;
       fEnabledFeatures:TVkPhysicalDeviceFeatures;
       fPointerToEnabledFeatures:PVkPhysicalDeviceFeatures;
       fAllocationManager:TpvVulkanAllocationManager;
       fAllocationCallbacks:PVkAllocationCallbacks;
       fDeviceHandle:TVkDevice;
       fDeviceVulkan:TVulkan;
       fUniversalQueueFamilyIndex:TpvInt32;
       fPresentQueueFamilyIndex:TpvInt32;
       fGraphicsQueueFamilyIndex:TpvInt32;
       fComputeQueueFamilyIndex:TpvInt32;
       fTransferQueueFamilyIndex:TpvInt32;
       fQueues:TpvVulkanQueues;
       fUniversalQueue:TpvVulkanQueue;
       fPresentQueue:TpvVulkanQueue;
       fGraphicsQueue:TpvVulkanQueue;
       fComputeQueue:TpvVulkanQueue;
       fTransferQueue:TpvVulkanQueue;
       fMemoryManager:TpvVulkanDeviceMemoryManager;
       fCanvasCommon:TObject;
      protected
      public
       constructor Create(const aInstance:TpvVulkanInstance;
                          const aPhysicalDevice:TpvVulkanPhysicalDevice=nil;
                          const aSurface:TpvVulkanSurface=nil;
                          const aAllocationManager:TpvVulkanAllocationManager=nil);
       destructor Destroy; override;
       procedure AddQueue(const aQueueFamilyIndex:TpvUInt32;const aQueuePriorities:array of TpvFloat;const aSurface:TpvVulkanSurface=nil);
       procedure AddQueues(const aUniversal:boolean=true;
                           const aPresent:boolean=true;
                           const aGraphics:boolean=true;
                           const aCompute:boolean=true;
                           const aTransfer:boolean=true;
                           const aSparseBinding:boolean=false;
                           const aSurface:TpvVulkanSurface=nil);
       procedure Initialize;
       procedure WaitIdle;
       property EnabledFeatures:PVkPhysicalDeviceFeatures read fPointerToEnabledFeatures;
      published
       property PhysicalDevice:TpvVulkanPhysicalDevice read fPhysicalDevice;
       property Surface:TpvVulkanSurface read fSurface;
       property EnabledLayerNames:TStringList read fEnabledLayerNames;
       property EnabledExtensionNames:TStringList read fEnabledExtensionNames;
       property Handle:TVkDevice read fDeviceHandle;
       property Commands:TVulkan read fDeviceVulkan;
       property UniversalQueueFamilyIndex:TpvInt32 read fUniversalQueueFamilyIndex;
       property PresentQueueFamilyIndex:TpvInt32 read fPresentQueueFamilyIndex;
       property GraphicsQueueFamilyIndex:TpvInt32 read fGraphicsQueueFamilyIndex;
       property ComputeQueueFamilyIndex:TpvInt32 read fComputeQueueFamilyIndex;
       property TransferQueueFamilyIndex:TpvInt32 read fTransferQueueFamilyIndex;
       property Queues:TpvVulkanQueues read fQueues;
       property UniversalQueue:TpvVulkanQueue read fUniversalQueue;
       property PresentQueue:TpvVulkanQueue read fPresentQueue;
       property GraphicsQueue:TpvVulkanQueue read fGraphicsQueue;
       property ComputeQueue:TpvVulkanQueue read fComputeQueue;
       property TransferQueue:TpvVulkanQueue read fTransferQueue;
       property MemoryManager:TpvVulkanDeviceMemoryManager read fMemoryManager;
       property CanvasCommon:TObject read fCanvasCommon write fCanvasCommon;
     end;

     TpvVulkanDeviceQueueCreateInfo=class(TpvVulkanObject)
      private
       fQueueFamilyIndex:TpvUInt32;
       fQueuePriorities:TVkFloatArray;
      public
       constructor Create(const aQueueFamilyIndex:TpvUInt32;const aQueuePriorities:array of TpvFloat);
       destructor Destroy; override;
      published
       property QueueFamilyIndex:TpvUInt32 read fQueueFamilyIndex;
       property QueuePriorities:TVkFloatArray read fQueuePriorities;
     end;

     TpvVulkanDeviceQueueCreateInfoList=class(TpvVulkanObjectList)
      private
       function GetItem(const Index:TVkSizeInt):TpvVulkanDeviceQueueCreateInfo;
       procedure SetItem(const Index:TVkSizeInt;const Item:TpvVulkanDeviceQueueCreateInfo);
      public
       property Items[const Index:TVkSizeInt]:TpvVulkanDeviceQueueCreateInfo read GetItem write SetItem; default;
     end;

     TpvVulkanResource=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fOwnsResource:boolean;
      public
       constructor Create; reintroduce; virtual;
       destructor Destroy; override;
       procedure Clear; virtual;
      published
       property Device:TpvVulkanDevice read fDevice write fDevice;
       property OwnsResource:boolean read fOwnsResource write fOwnsResource;
     end;

     PpvVulkanDeviceMemoryAllocationType=^TpvVulkanDeviceMemoryAllocationType;
     TpvVulkanDeviceMemoryAllocationType=
      (
       vdmatFree,
       vdmatUnknown,
       vdmatBuffer,
       vdmatImageLinear,
       vdmatImageOptimal
      );

     PpvVulkanDeviceMemoryChunkFlag=^TpvVulkanDeviceMemoryChunkFlag;
     TpvVulkanDeviceMemoryChunkFlag=
      (
       vdmcfPersistentMapped
      );

     PpvVulkanDeviceMemoryChunkFlags=^TpvVulkanDeviceMemoryChunkFlags;
     TpvVulkanDeviceMemoryChunkFlags=set of TpvVulkanDeviceMemoryChunkFlag;

     TpvVulkanDeviceMemoryChunkBlock=class;

     PpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey=^TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
     TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey=TVkDeviceSize;

     PpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue=^TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue;
     TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue=TpvVulkanDeviceMemoryChunkBlock;

     PpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=^TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
     TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=class(TpvVulkanObject)
      private
       fKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
       fValue:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue;
       fLeft:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fRight:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fParent:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fColor:boolean;
      public
       constructor Create(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey=0;
                          const aValue:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue=nil;
                          const aLeft:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                          const aRight:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                          const aParent:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                          const aColor:boolean=false);
       destructor Destroy; override;
       procedure Clear;
       function Minimum:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Maximum:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Predecessor:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Successor:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
      published
       property Key:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey read fKey write fKey;
       property Value:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue read fValue write fValue;
       property Left:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fLeft write fLeft;
       property Right:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fRight write fRight;
       property Parent:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fParent write fParent;
       property Color:boolean read fColor write fColor;
     end;

     TpvVulkanDeviceMemoryChunkBlockRedBlackTree=class(TpvVulkanObject)
      private
       fRoot:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
      protected
       procedure RotateLeft(x:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
       procedure RotateRight(x:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Clear;
       function Find(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey):TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function Insert(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
                       const aValue:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue):TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       procedure Remove(const aNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
       procedure Delete(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey);
      published
       function LeftMost:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       function RightMost:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       property Root:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode read fRoot;
     end;

     TpvVulkanDeviceMemoryChunk=class;

     TpvVulkanDeviceMemoryChunkBlock=class(TpvVulkanObject)
      private
       fMemoryChunk:TpvVulkanDeviceMemoryChunk;
       fOffset:TVkDeviceSize;
       fSize:TVkDeviceSize;
       fAllocationType:TpvVulkanDeviceMemoryAllocationType;
       fOffsetRedBlackTreeNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
       fSizeRedBlackTreeNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
      public
       constructor Create(const aMemoryChunk:TpvVulkanDeviceMemoryChunk;
                          const aOffset:TVkDeviceSize;
                          const aSize:TVkDeviceSize;
                          const aAllocationType:TpvVulkanDeviceMemoryAllocationType);
       destructor Destroy; override;
       procedure Update(const aOffset:TVkDeviceSize;
                        const aSize:TVkDeviceSize;
                        const aAllocationType:TpvVulkanDeviceMemoryAllocationType);
      published
       property MemoryChunk:TpvVulkanDeviceMemoryChunk read fMemoryChunk;
       property Offset:TVkDeviceSize read fOffset;
       property Size:TVkDeviceSize read fSize;
       property AllocationType:TpvVulkanDeviceMemoryAllocationType read fAllocationType;
     end;

     PpvVulkanDeviceMemoryManagerChunkList=^TpvVulkanDeviceMemoryManagerChunkList;
     PpvVulkanDeviceMemoryManagerChunkLists=^TpvVulkanDeviceMemoryManagerChunkLists;

     TpvVulkanDeviceMemoryChunk=class(TpvVulkanObject)
      private
       fMemoryManager:TpvVulkanDeviceMemoryManager;
       fPreviousMemoryChunk:TpvVulkanDeviceMemoryChunk;
       fNextMemoryChunk:TpvVulkanDeviceMemoryChunk;
       fLock:TCriticalSection;
       fMemoryChunkFlags:TpvVulkanDeviceMemoryChunkFlags;
       fMemoryChunkList:PpvVulkanDeviceMemoryManagerChunkList;
       fSize:TVkDeviceSize;
       fUsed:TVkDeviceSize;
       fMappedOffset:TVkDeviceSize;
       fMappedSize:TVkDeviceSize;
       fOffsetRedBlackTree:TpvVulkanDeviceMemoryChunkBlockRedBlackTree;
       fSizeRedBlackTree:TpvVulkanDeviceMemoryChunkBlockRedBlackTree;
       fMemoryTypeIndex:TpvUInt32;
       fMemoryTypeBits:TpvUInt32;
       fMemoryHeapIndex:TpvUInt32;
       fMemoryPropertyFlags:TVkMemoryPropertyFlags;
       fMemoryHeapFlags:TVkMemoryHeapFlags;
       fMemoryHandle:TVkDeviceMemory;
       fMemory:PVkVoid;
      public
       constructor Create(const aMemoryManager:TpvVulkanDeviceMemoryManager;
                          const aMemoryChunkFlags:TpvVulkanDeviceMemoryChunkFlags;
                          const aSize:TVkDeviceSize;
                          const aSizeIsMinimumSize:boolean;
                          const aMemoryTypeBits:TpvUInt32;
                          const aMemoryRequiredPropertyFlags:TVkMemoryPropertyFlags;
                          const aMemoryPreferredPropertyFlags:TVkMemoryPropertyFlags;
                          const aMemoryAvoidPropertyFlags:TVkMemoryPropertyFlags;
                          const aMemoryRequiredHeapFlags:TVkMemoryHeapFlags;
                          const aMemoryPreferredHeapFlags:TVkMemoryHeapFlags;
                          const aMemoryAvoidHeapFlags:TVkMemoryHeapFlags;
                          const aMemoryChunkList:PpvVulkanDeviceMemoryManagerChunkList);
       destructor Destroy; override;
       function AllocateMemory(out aOffset:TVkDeviceSize;const aSize,aAlignment:TVkDeviceSize;const aAllocationType:TpvVulkanDeviceMemoryAllocationType):boolean;
       function ReallocateMemory(var aOffset:TVkDeviceSize;const aSize,aAlignment:TVkDeviceSize):boolean;
       function FreeMemory(const aOffset:TVkDeviceSize):boolean;
       function MapMemory(const aOffset:TVkDeviceSize=0;const aSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
       procedure UnmapMemory;
       procedure FlushMappedMemory;
       procedure FlushMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
       procedure InvalidateMappedMemory;
       procedure InvalidateMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
       property Memory:PVkVoid read fMemory;
      published
       property MemoryManager:TpvVulkanDeviceMemoryManager read fMemoryManager;
       property Size:TVkDeviceSize read fSize;
       property MemoryPropertyFlags:TVkMemoryPropertyFlags read fMemoryPropertyFlags;
       property MemoryHeapFlags:TVkMemoryPropertyFlags read fMemoryHeapFlags;
       property MemoryTypeIndex:TpvUInt32 read fMemoryTypeIndex;
       property MemoryTypeBits:TpvUInt32 read fMemoryTypeBits;
       property MemoryHeapIndex:TpvUInt32 read fMemoryHeapIndex;
       property Handle:TVkDeviceMemory read fMemoryHandle;
     end;

     PpvVulkanDeviceMemoryBlockFlag=^TpvVulkanDeviceMemoryBlockFlag;
     TpvVulkanDeviceMemoryBlockFlag=
      (
       vdmbfOwnSingleMemoryChunk,
       vdmbfPersistentMapped
      );

     PpvVulkanDeviceMemoryBlockFlags=^TpvVulkanDeviceMemoryBlockFlags;
     TpvVulkanDeviceMemoryBlockFlags=set of TpvVulkanDeviceMemoryBlockFlag;

     TpvVulkanDeviceMemoryBlock=class(TpvVulkanObject)
      private
       fMemoryManager:TpvVulkanDeviceMemoryManager;
       fMemoryChunk:TpvVulkanDeviceMemoryChunk;
       fOffset:TVkDeviceSize;
       fSize:TVkDeviceSize;
       fPreviousMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fNextMemoryBlock:TpvVulkanDeviceMemoryBlock;
      public
       constructor Create(const aMemoryManager:TpvVulkanDeviceMemoryManager;
                          const aMemoryChunk:TpvVulkanDeviceMemoryChunk;
                          const aOffset:TVkDeviceSize;
                          const aSize:TVkDeviceSize);
       destructor Destroy; override;
       function MapMemory(const aOffset:TVkDeviceSize=0;const aSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
       procedure UnmapMemory;
       procedure FlushMappedMemory;
       procedure FlushMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
       procedure InvalidateMappedMemory;
       procedure InvalidateMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
       function Fill(const aData:PVkVoid;const aSize:TVkDeviceSize):TVkDeviceSize;
      published
       property MemoryManager:TpvVulkanDeviceMemoryManager read fMemoryManager;
       property MemoryChunk:TpvVulkanDeviceMemoryChunk read fMemoryChunk;
       property Offset:TVkDeviceSize read fOffset;
       property Size:TVkDeviceSize read fSize;
     end;

     TpvVulkanDeviceMemoryManagerChunkList=record
      First:TpvVulkanDeviceMemoryChunk;
      Last:TpvVulkanDeviceMemoryChunk;
     end;

     TpvVulkanDeviceMemoryManagerChunkLists=array[0..31] of TpvVulkanDeviceMemoryManagerChunkList;

     TpvVulkanDeviceMemoryManager=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fLock:TCriticalSection;
       fMemoryChunkList:TpvVulkanDeviceMemoryManagerChunkList;
       fFirstMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fLastMemoryBlock:TpvVulkanDeviceMemoryBlock;
      public
       constructor Create(const aDevice:TpvVulkanDevice);
       destructor Destroy; override;
       function AllocateMemoryBlock(const aMemoryBlockFlags:TpvVulkanDeviceMemoryBlockFlags;
                                    const aMemoryBlockSize:TVkDeviceSize;
                                    const aMemoryBlockAlignment:TVkDeviceSize;
                                    const aMemoryTypeBits:TpvUInt32;
                                    const aMemoryRequiredPropertyFlags:TVkMemoryPropertyFlags;
                                    const aMemoryPreferredPropertyFlags:TVkMemoryPropertyFlags;
                                    const aMemoryAvoidPropertyFlags:TVkMemoryPropertyFlags;
                                    const aMemoryRequiredHeapFlags:TVkMemoryHeapFlags;
                                    const aMemoryPreferredHeapFlags:TVkMemoryHeapFlags;
                                    const aMemoryAvoidHeapFlags:TVkMemoryHeapFlags;
                                    const aMemoryAllocationType:TpvVulkanDeviceMemoryAllocationType):TpvVulkanDeviceMemoryBlock;
       function FreeMemoryBlock(const aMemoryBlock:TpvVulkanDeviceMemoryBlock):boolean;
     end;

     TpvVulkanQueueFamilyIndices=array of TpvUInt32;

     TpvVulkanFence=class;

     TpvVulkanCommandBuffer=class;

     TpvVulkanBufferUseTemporaryStagingBufferMode=
      (
       vbutsbmAutomatic,
       vbutsbmYes,
       vbutsbmNo
      );

     PpvVulkanBufferFlag=^TpvVulkanBufferFlag;
     TpvVulkanBufferFlag=
      (
       vbfOwnSingleMemoryChunk,
       vbfPersistentMapped
      );

     PpvVulkanBufferFlags=^TpvVulkanBufferFlags;
     TpvVulkanBufferFlags=set of TpvVulkanBufferFlag;

     TpvVulkanBuffer=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fSize:TVkDeviceSize;
       fMemoryPropertyFlags:TVkMemoryPropertyFlags;
       fBufferFlags:TpvVulkanBufferFlags;
       fBufferHandle:TVkBuffer;
       fMemoryRequirements:TVkMemoryRequirements;
       fMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fQueueFamilyIndices:TpvVulkanQueueFamilyIndices;
       fCountQueueFamilyIndices:TpvInt32;
       fDescriptorBufferInfo:TVkDescriptorBufferInfo;
       procedure Bind;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aSize:TVkDeviceSize;
                          const aUsage:TVkBufferUsageFlags;
                          const aSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                          const aQueueFamilyIndices:TVkUInt32List=nil;
                          const aMemoryRequiredPropertyFlags:TVkMemoryPropertyFlags=TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
                          const aMemoryPreferredPropertyFlags:TVkMemoryPropertyFlags=TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
                          const aMemoryAvoidPropertyFlags:TVkMemoryPropertyFlags=0;
                          const aMemoryRequiredHeapFlags:TVkMemoryHeapFlags=0;
                          const aMemoryPreferredHeapFlags:TVkMemoryHeapFlags=0;
                          const aMemoryAvoidHeapFlags:TVkMemoryHeapFlags=0;
                          const aBufferFlags:TpvVulkanBufferFlags=[]);
       destructor Destroy; override;
       procedure UploadData(const aTransferQueue:TpvVulkanQueue;
                            const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                            const aTransferFence:TpvVulkanFence;
                            const aData;
                            const aDataOffset:TVkDeviceSize;
                            const aDataSize:TVkDeviceSize;
                            const aUseTemporaryStagingBufferMode:TpvVulkanBufferUseTemporaryStagingBufferMode=vbutsbmAutomatic);
       procedure UpdateData(const aData;
                            const aDataOffset:TVkDeviceSize;
                            const aDataSize:TVkDeviceSize);
{      procedure UploadBarrier(const aCommandBuffer:TpvVulkanCommandBuffer);
       procedure DownloadBarrier(const aCommandBuffer:TpvVulkanCommandBuffer);}
       property DescriptorBufferInfo:TVkDescriptorBufferInfo read fDescriptorBufferInfo;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkBuffer read fBufferHandle;
       property Size:TVkDeviceSize read fSize;
       property Memory:TpvVulkanDeviceMemoryBlock read fMemoryBlock;
     end;

     TpvVulkanBufferView=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fBufferViewHandle:TVkBufferView;
       fBuffer:TpvVulkanBuffer;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aBuffer:TpvVulkanBuffer;
                          const aFormat:TVkFormat;
                          const aOffset:TVkDeviceSize=0;
                          const aRange:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aBufferView:TVkBufferView;
                          const aBuffer:TpvVulkanBuffer=nil); reintroduce; overload;
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkRenderPass read fBufferViewHandle;
       property Buffer:TpvVulkanBuffer read fBuffer write fBuffer;
     end;

     TpvVulkanEvent=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fEventHandle:TVkEvent;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aFlags:TVkEventCreateFlags=TVkEventCreateFlags(0));
       destructor Destroy; override;
       function GetStatus:TVkResult;
       function SetEvent:TVkResult;
       function Reset:TVkResult;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkEvent read fEventHandle;
     end;

     TpvVulkanFence=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fFenceHandle:TVkFence;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aFlags:TVkFenceCreateFlags=TVkFenceCreateFlags(0));
       destructor Destroy; override;
       function GetStatus:TVkResult;
       function Reset:TVkResult; overload;
       class function Reset(const aFences:array of TpvVulkanFence):TVkResult; overload;
       function WaitFor(const aTimeOut:TpvUInt64=TpvUInt64(TpvInt64(-1))):TVkResult; overload;
       class function WaitFor(const aFences:array of TpvVulkanFence;const aWaitAll:boolean=true;const aTimeOut:TpvUInt64=TpvUInt64(TpvInt64(-1))):TVkResult; overload;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkFence read fFenceHandle;
     end;

     TpvVulkanSemaphore=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fSemaphoreHandle:TVkSemaphore;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aFlags:TVkSemaphoreCreateFlags=TVkSemaphoreCreateFlags(0));
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkSemaphore read fSemaphoreHandle;
     end;

     TpvVulkanQueue=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fQueueHandle:TVkQueue;
       fQueueFamilyIndex:TpvUInt32;
       fHasSupportForSparseBindings:boolean;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aQueue:TVkQueue;
                          const aQueueFamilyIndex:TpvUInt32);
       destructor Destroy; override;
       procedure Submit(const aSubmitCount:TpvUInt32;const aSubmits:PVkSubmitInfo;const aFence:TpvVulkanFence=nil);
       procedure BindSparse(const aBindInfoCount:TpvUInt32;const aBindInfo:PVkBindSparseInfo;const aFence:TpvVulkanFence=nil);
       procedure WaitIdle;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkQueue read fQueueHandle;
       property QueueFamilyIndex:TpvUInt32 read fQueueFamilyIndex;
       property HasSupportForSparseBindings:boolean read fHasSupportForSparseBindings;
     end;

     TpvVulkanCommandPool=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fQueueFamilyIndex:TpvUInt32;
       fFlags:TVkCommandPoolCreateFlags;
       fCommandPoolHandle:TVkCommandPool;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aQueueFamilyIndex:TpvUInt32;
                          const aFlags:TVkCommandPoolCreateFlags=TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property QueueFamilyIndex:TpvUInt32 read fQueueFamilyIndex;
       property Handle:TVkCommandPool read fCommandPoolHandle;
     end;

     TpvVulkanImage=class;

     TpvVulkanCommandBuffer=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fCommandPool:TpvVulkanCommandPool;
       fLevel:TVkCommandBufferLevel;
       fCommandBufferHandle:TVkCommandBuffer;
//     fFence:TpvVulkanFence;
      public
       constructor Create(const aCommandPool:TpvVulkanCommandPool;
                          const aLevel:TVkCommandBufferLevel;
                          const aCommandBufferHandle:TVkCommandBuffer); reintroduce; overload;
       constructor Create(const aCommandPool:TpvVulkanCommandPool;
                          const aLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY); reintroduce; overload;
       destructor Destroy; override;
       class function Allocate(const aCommandPool:TpvVulkanCommandPool;
                               const aLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY;
                               const aCommandBufferCount:TpvUInt32=1):TpvVulkanObjectList;
       procedure BeginRecording(const aFlags:TVkCommandBufferUsageFlags=0;const aInheritanceInfo:PVkCommandBufferInheritanceInfo=nil);
       procedure BeginRecordingPrimary;
       procedure BeginRecordingSecondary(const aRenderPass:TVkRenderPass;const aSubPass:TpvUInt32;const aFrameBuffer:TVkFramebuffer;const aOcclusionQueryEnable:boolean;const aQueryFlags:TVkQueryControlFlags;const aPipelineStatistics:TVkQueryPipelineStatisticFlags;const aFlags:TVkCommandBufferUsageFlags=TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT));
       procedure EndRecording;
       procedure Reset(const aFlags:TVkCommandBufferResetFlags=TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
       procedure CmdBindPipeline(pipelineBindPoint:TVkPipelineBindPoint;pipeline:TVkPipeline);
       procedure CmdSetViewport(firstViewport:TpvUInt32;viewportCount:TpvUInt32;const aViewports:PVkViewport);
       procedure CmdSetScissor(firstScissor:TpvUInt32;scissorCount:TpvUInt32;const aScissors:PVkRect2D);
       procedure CmdSetLineWidth(lineWidth:TpvFloat);
       procedure CmdSetDepthBias(depthBiasConstantFactor:TpvFloat;depthBiasClamp:TpvFloat;depthBiasSlopeFactor:TpvFloat);
       procedure CmdSetBlendConstants(const blendConstants:TpvFloat);
       procedure CmdSetDepthBounds(minDepthBounds:TpvFloat;maxDepthBounds:TpvFloat);
       procedure CmdSetStencilCompareMask(faceMask:TVkStencilFaceFlags;compareMask:TpvUInt32);
       procedure CmdSetStencilWriteMask(faceMask:TVkStencilFaceFlags;writeMask:TpvUInt32);
       procedure CmdSetStencilReference(faceMask:TVkStencilFaceFlags;reference:TpvUInt32);
       procedure CmdBindDescriptorSets(pipelineBindPoint:TVkPipelineBindPoint;layout:TVkPipelineLayout;firstSet:TpvUInt32;descriptorSetCount:TpvUInt32;const aDescriptorSets:PVkDescriptorSet;dynamicOffsetCount:TpvUInt32;const aDynamicOffsets:PpvUInt32);
       procedure CmdBindIndexBuffer(buffer:TVkBuffer;offset:TVkDeviceSize;indexType:TVkIndexType);
       procedure CmdBindVertexBuffers(firstBinding:TpvUInt32;bindingCount:TpvUInt32;const aBuffers:PVkBuffer;const aOffsets:PVkDeviceSize);
       procedure CmdDraw(vertexCount:TpvUInt32;instanceCount:TpvUInt32;firstVertex:TpvUInt32;firstInstance:TpvUInt32);
       procedure CmdDrawIndexed(indexCount:TpvUInt32;instanceCount:TpvUInt32;firstIndex:TpvUInt32;vertexOffset:TpvInt32;firstInstance:TpvUInt32);
       procedure CmdDrawIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TpvUInt32;stride:TpvUInt32);
       procedure CmdDrawIndexedIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TpvUInt32;stride:TpvUInt32);
       procedure CmdDispatch(x:TpvUInt32;y:TpvUInt32;z:TpvUInt32);
       procedure CmdDispatchIndirect(buffer:TVkBuffer;offset:TVkDeviceSize);
       procedure CmdCopyBuffer(srcBuffer:TVkBuffer;dstBuffer:TVkBuffer;regionCount:TpvUInt32;const aRegions:PVkBufferCopy);
       procedure CmdCopyImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkImageCopy);
       procedure CmdBlitImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkImageBlit;filter:TVkFilter);
       procedure CmdCopyBufferToImage(srcBuffer:TVkBuffer;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkBufferImageCopy);
       procedure CmdCopyImageToBuffer(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstBuffer:TVkBuffer;regionCount:TpvUInt32;const aRegions:PVkBufferImageCopy);
       procedure CmdUpdateBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;dataSize:TVkDeviceSize;const aData:PVkVoid);
       procedure CmdFillBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;size:TVkDeviceSize;data:TpvUInt32);
       procedure CmdClearColorImage(image:TVkImage;imageLayout:TVkImageLayout;const aColor:PVkClearColorValue;rangeCount:TpvUInt32;const aRanges:PVkImageSubresourceRange);
       procedure CmdClearDepthStencilImage(image:TVkImage;imageLayout:TVkImageLayout;const aDepthStencil:PVkClearDepthStencilValue;rangeCount:TpvUInt32;const aRanges:PVkImageSubresourceRange);
       procedure CmdClearAttachments(attachmentCount:TpvUInt32;const aAttachments:PVkClearAttachment;rectCount:TpvUInt32;const aRects:PVkClearRect);
       procedure CmdResolveImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkImageResolve);
       procedure CmdSetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
       procedure CmdResetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
       procedure CmdWaitEvents(eventCount:TpvUInt32;const aEvents:PVkEvent;srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;memoryBarrierCount:TpvUInt32;const aMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TpvUInt32;const aBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TpvUInt32;const aImageMemoryBarriers:PVkImageMemoryBarrier);
       procedure CmdPipelineBarrier(srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;dependencyFlags:TVkDependencyFlags;memoryBarrierCount:TpvUInt32;const aMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TpvUInt32;const aBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TpvUInt32;const aImageMemoryBarriers:PVkImageMemoryBarrier);
       procedure CmdBeginQuery(queryPool:TVkQueryPool;query:TpvUInt32;flags:TVkQueryControlFlags);
       procedure CmdEndQuery(queryPool:TVkQueryPool;query:TpvUInt32);
       procedure CmdResetQueryPool(queryPool:TVkQueryPool;firstQuery:TpvUInt32;queryCount:TpvUInt32);
       procedure CmdWriteTimestamp(pipelineStage:TVkPipelineStageFlagBits;queryPool:TVkQueryPool;query:TpvUInt32);
       procedure CmdCopyQueryPoolResults(queryPool:TVkQueryPool;firstQuery:TpvUInt32;queryCount:TpvUInt32;dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;stride:TVkDeviceSize;flags:TVkQueryResultFlags);
       procedure CmdPushConstants(layout:TVkPipelineLayout;stageFlags:TVkShaderStageFlags;offset:TpvUInt32;size:TpvUInt32;const aValues:PVkVoid);
       procedure CmdBeginRenderPass(const aRenderPassBegin:PVkRenderPassBeginInfo;contents:TVkSubpassContents);
       procedure CmdNextSubpass(contents:TVkSubpassContents);
       procedure CmdEndRenderPass;
       procedure CmdExecuteCommands(commandBufferCount:TpvUInt32;const aCommandBuffers:PVkCommandBuffer);
       procedure CmdExecute(const aCommandBuffer:TpvVulkanCommandBuffer);
       procedure MetaCmdPresentToDrawImageBarrier(const aImage:TpvVulkanImage;const aDoTransitionToColorAttachmentOptimalLayout:boolean=true);
       procedure MetaCmdDrawToPresentImageBarrier(const aImage:TpvVulkanImage;const aDoTransitionToPresentSrcLayout:boolean=true);
       procedure MetaCmdMemoryBarrier(const aSrcStageMask,aDstStageMask:TVkPipelineStageFlags;const aSrcAccessMask,aDstAccessMask:TVkAccessFlags);
       procedure Execute(const aQueue:TpvVulkanQueue;const aWaitDstStageFlags:TVkPipelineStageFlags;const aWaitSemaphore:TpvVulkanSemaphore=nil;const aSignalSemaphore:TpvVulkanSemaphore=nil;const aFence:TpvVulkanFence=nil;const aDoWaitAndResetFence:boolean=true);
      published
       property Device:TpvVulkanDevice read fDevice;
       property CommandPool:TpvVulkanCommandPool read fCommandPool;
       property Level:TVkCommandBufferLevel read fLevel;
       property Handle:TVkCommandBuffer read fCommandBufferHandle;
     end;

     TpvVulkanCommandBufferSubmitQueueSubmitInfos=array of TVkSubmitInfo;

     TpvVulkanCommandBufferSubmitQueueSubmitInfoSubmitInfoWaitSemaphores=array of TVkSemaphore;

     TpvVulkanCommandBufferSubmitQueueSubmitInfoWaitDstStageFlags=array of TVkPipelineStageFlags;

     TpvVulkanCommandBufferSubmitQueueSubmitInfoSubmitInfoSignalSemaphores=array of TVkSemaphore;

     TpvVulkanCommandBufferSubmitQueue=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fQueue:TpvVulkanQueue;
       fSubmitInfos:TpvVulkanCommandBufferSubmitQueueSubmitInfos;
       fSubmitInfoWaitSemaphores:TpvVulkanCommandBufferSubmitQueueSubmitInfoSubmitInfoWaitSemaphores;
       fSubmitInfoWaitDstStageFlags:TpvVulkanCommandBufferSubmitQueueSubmitInfoWaitDstStageFlags;
       fSubmitInfoSignalSemaphores:TpvVulkanCommandBufferSubmitQueueSubmitInfoSubmitInfoSignalSemaphores;
       fCountSubmitInfos:TpvInt32;
      public
       constructor Create(const aQueue:TpvVulkanQueue); reintroduce;
       destructor Destroy; override;
       procedure Reset;
       procedure QueueSubmit(const aCommandBuffer:TpvVulkanCommandBuffer;const aWaitDstStageFlags:TVkPipelineStageFlags;const aWaitSemaphore:TpvVulkanSemaphore=nil;const aSignalSemaphore:TpvVulkanSemaphore=nil);
       procedure SubmitQueued(const aFence:TpvVulkanFence=nil;const aDoWaitAndResetFence:boolean=true);
     end;

     TpvVulkanRenderPassAttachmentDescriptions=array of TVkAttachmentDescription;

     TpvVulkanRenderPassAttachmentReferences=array of TVkAttachmentReference;

     PpvVulkanRenderPassSubpassDescription=^TpvVulkanRenderPassSubpassDescription;
     TpvVulkanRenderPassSubpassDescription=record
      Flags:TVkSubpassDescriptionFlags;
      PipelineBindPoint:TVkPipelineBindPoint;
      InputAttachments:array of TpvInt32;
      ColorAttachments:array of TpvInt32;
      ResolveAttachments:array of TpvInt32;
      DepthStencilAttachment:TpvInt32;
      PreserveAttachments:array of TpvUInt32;
      aInputAttachments:TpvVulkanRenderPassAttachmentReferences;
      aColorAttachments:TpvVulkanRenderPassAttachmentReferences;
      aResolveAttachments:TpvVulkanRenderPassAttachmentReferences;
     end;

     TpvVulkanRenderPassSubpassDescriptions=array of TpvVulkanRenderPassSubpassDescription;

     TpvVulkanFrameBuffer=class;

     TpvVulkanRenderPass=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fRenderPassHandle:TVkRenderPass;
       fAttachmentDescriptions:TpvVulkanRenderPassAttachmentDescriptions;
       fCountAttachmentDescriptions:TpvInt32;
       fAttachmentReferences:TpvVulkanRenderPassAttachmentReferences;
       fCountAttachmentReferences:TpvInt32;
       fRenderPassSubpassDescriptions:TpvVulkanRenderPassSubpassDescriptions;
       fSubpassDescriptions:TVkSubpassDescriptionArray;
       fCountSubpassDescriptions:TpvInt32;
       fSubpassDependencies:TVkSubpassDependencyArray;
       fCountSubpassDependencies:TpvInt32;
       fClearValues:TVkClearValueArray;
       function GetClearValue(const Index:TpvUInt32):PVkClearValue;
      public
       constructor Create(const aDevice:TpvVulkanDevice);
       destructor Destroy; override;
       function AddAttachmentDescription(const aFlags:TVkAttachmentDescriptionFlags;
                                         const aFormat:TVkFormat;
                                         const aSamples:TVkSampleCountFlagBits;
                                         const aLoadOp:TVkAttachmentLoadOp;
                                         const aStoreOp:TVkAttachmentStoreOp;
                                         const aStencilLoadOp:TVkAttachmentLoadOp;
                                         const aStencilStoreOp:TVkAttachmentStoreOp;
                                         const aInitialLayout:TVkImageLayout;
                                         const aFinalLayout:TVkImageLayout):TpvUInt32;
       function AddAttachmentReference(const aAttachment:TpvUInt32;
                                       const aLayout:TVkImageLayout):TpvUInt32;
       function AddSubpassDescription(const aFlags:TVkSubpassDescriptionFlags;
                                      const aPipelineBindPoint:TVkPipelineBindPoint;
                                      const aInputAttachments:array of TpvInt32;
                                      const aColorAttachments:array of TpvInt32;
                                      const aResolveAttachments:array of TpvInt32;
                                      const aDepthStencilAttachment:TpvInt32;
                                      const aPreserveAttachments:array of TpvUInt32):TpvUInt32;
       function AddSubpassDependency(const aSrcSubpass:TpvUInt32;
                                     const aDstSubpass:TpvUInt32;
                                     const aSrcStageMask:TVkPipelineStageFlags;
                                     const aDstStageMask:TVkPipelineStageFlags;
                                     const aSrcAccessMask:TVkAccessFlags;
                                     const aDstAccessMask:TVkAccessFlags;
                                     const aDependencyFlags:TVkDependencyFlags):TpvUInt32;
       procedure Initialize;
       procedure BeginRenderPass(const aCommandBuffer:TpvVulkanCommandBuffer;
                                 const aFrameBuffer:TpvVulkanFrameBuffer;
                                 const aSubpassContents:TVkSubpassContents;
                                 const aOffsetX,aOffsetY,aWidth,aHeight:TpvUInt32);
       procedure EndRenderPass(const aCommandBuffer:TpvVulkanCommandBuffer);
       property ClearValues[const Index:TpvUInt32]:PVkClearValue read GetClearValue;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkRenderPass read fRenderPassHandle;
     end;

     TpvVulkanSampler=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fSamplerHandle:TVkSampler;
       fDoDestroy:boolean;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aSampler:TVkSampler;
                          const aDoDestroy:boolean=true); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aMagFilter:TVkFilter;
                          const aMinFilter:TVkFilter;
                          const aMipmapMode:TVkSamplerMipmapMode;
                          const aAddressModeU:TVkSamplerAddressMode;
                          const aAddressModeV:TVkSamplerAddressMode;
                          const aAddressModeW:TVkSamplerAddressMode;
                          const aMipLodBias:TpvFloat;
                          const aAnisotropyEnable:boolean;
                          const aMaxAnisotropy:TpvFloat;
                          const aCompareEnable:boolean;
                          const aCompareOp:TVkCompareOp;
                          const aMinLod:TpvFloat;
                          const aMaxLod:TpvFloat;
                          const aBorderColor:TVkBorderColor;
                          const aUnnormalizedCoordinates:boolean); reintroduce; overload;
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkSampler read fSamplerHandle;
     end;

     TpvVulkanImageView=class;

     TpvVulkanImage=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fImageHandle:TVkImage;
       fImageView:TpvVulkanImageView;
       fDoDestroy:boolean;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aImage:TVkImage;
                          const aImageView:TpvVulkanImageView=nil;
                          const aDoDestroy:boolean=true); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aFlags:TVkImageCreateFlags;
                          const aImageType:TVkImageType;
                          const aFormat:TVkFormat;
                          const aExtentWidth:TpvUInt32;
                          const aExtentHeight:TpvUInt32;
                          const aExtentDepth:TpvUInt32;
                          const aMipLevels:TpvUInt32;
                          const aArrayLayers:TpvUInt32;
                          const aSamples:TVkSampleCountFlagBits;
                          const aTiling:TVkImageTiling;
                          const aUsage:TVkImageUsageFlags;
                          const aSharingMode:TVkSharingMode;
                          const aQueueFamilyIndexCount:TpvUInt32;
                          const aQueueFamilyIndices:PpvUInt32;
                          const aInitialLayout:TVkImageLayout); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aFlags:TVkImageCreateFlags;
                          const aImageType:TVkImageType;
                          const aFormat:TVkFormat;
                          const aExtentWidth:TpvUInt32;
                          const aExtentHeight:TpvUInt32;
                          const aExtentDepth:TpvUInt32;
                          const aMipLevels:TpvUInt32;
                          const aArrayLayers:TpvUInt32;
                          const aSamples:TVkSampleCountFlagBits;
                          const aTiling:TVkImageTiling;
                          const aUsage:TVkImageUsageFlags;
                          const aSharingMode:TVkSharingMode;
                          const aQueueFamilyIndices:array of TpvUInt32;
                          const aInitialLayout:TVkImageLayout); reintroduce; overload;
       destructor Destroy; override;
       procedure SetLayout(const aAspectMask:TVkImageAspectFlags;
                           const aOldImageLayout:TVkImageLayout;
                           const aNewImageLayout:TVkImageLayout;
                           const aRange:PVkImageSubresourceRange;
                           const aCommandBuffer:TpvVulkanCommandBuffer;
                           const aQueue:TpvVulkanQueue=nil;
                           const aFence:TpvVulkanFence=nil;
                           const aBeginAndExecuteCommandBuffer:boolean=false;
                           const aSrcQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED);
                           const aDstQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED));
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkImage read fImageHandle;
       property ImageView:TpvVulkanImageView read fImageView write fImageView;
     end;

     TpvVulkanImageView=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fImageViewHandle:TVkImageView;
       fImage:TpvVulkanImage;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aImageView:TVkImageView;
                          const aImage:TpvVulkanImage=nil); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aImage:TpvVulkanImage;
                          const aImageViewType:TVkImageViewType;
                          const aFormat:TvkFormat;
                          const aComponentRed:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                          const aComponentGreen:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                          const aComponentBlue:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                          const aComponentAlpha:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                          const aImageAspectFlags:TVkImageAspectFlags=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
                          const aBaseMipLevel:TpvUInt32=0;
                          const aCountMipMapLevels:TpvUInt32=1;
                          const aBaseArrayLayer:TpvUInt32=1;
                          const aCountArrayLayers:TpvUInt32=0); reintroduce; overload;
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkRenderPass read fImageViewHandle;
       property Image:TpvVulkanImage read fImage write fImage;
     end;

     TpvVulkanFrameBufferAttachment=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fWidth:TpvUInt32;
       fHeight:TpvUInt32;
       fFormat:TVkFormat;
       fImage:TpvVulkanImage;
       fImageView:TpvVulkanImageView;
       fMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fDoDestroy:boolean;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aGraphicsQueue:TpvVulkanQueue;
                          const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                          const aGraphicsCommandBufferFence:TpvVulkanFence;
                          const aWidth:TpvUInt32;
                          const aHeight:TpvUInt32;
                          const aFormat:TVkFormat;
                          const aUsage:TVkBufferUsageFlags); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aImage:TpvVulkanImage;
                          const aImageView:TpvVulkanImageView;
                          const aWidth:TpvUInt32;
                          const aHeight:TpvUInt32;
                          const aFormat:TVkFormat;
                          const aDoDestroy:boolean=true); reintroduce; overload;
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Width:TpvUInt32 read fWidth;
       property Height:TpvUInt32 read fHeight;
       property Format:TVkFormat read fFormat;
       property Image:TpvVulkanImage read fImage;
       property ImageView:TpvVulkanImageView read fImageView;
       property Memory:TpvVulkanDeviceMemoryBlock read fMemoryBlock;
     end;

     TpvVulkanFrameBufferAttachments=array of TpvVulkanFrameBufferAttachment;

     TpvVulkanFrameBufferAttachmentImageViews=array of TVkImageView;

     TpvVulkanFrameBuffer=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fFrameBufferHandle:TVkFrameBuffer;
       fFrameBufferAttachments:TpvVulkanFrameBufferAttachments;
       fFrameBufferAttachmentImageViews:TpvVulkanFrameBufferAttachmentImageViews;
       fCountFrameBufferAttachments:TpvInt32;
       fRenderPass:TpvVulkanRenderPass;
       fWidth:TpvUInt32;
       fHeight:TpvUInt32;
       fLayers:TpvUInt32;
       fDoDestroy:boolean;
       fDoDestroyAttachments:boolean;
       function GetFrameBufferAttachment(const aIndex:TpvInt32):TpvVulkanFrameBufferAttachment;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aRenderPass:TpvVulkanRenderPass;
                          const aWidth:TpvUInt32;
                          const aHeight:TpvUInt32;
                          const aLayers:TpvUInt32); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aRenderPass:TpvVulkanRenderPass;
                          const aWidth:TpvUInt32;
                          const aHeight:TpvUInt32;
                          const aLayers:TpvUInt32;
                          const aFrameBufferAttachments:array of TpvVulkanFrameBufferAttachment;
                          const aDoDestroyAttachments:boolean=true); reintroduce; overload;
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aRenderPass:TpvVulkanRenderPass;
                          const aWidth:TpvUInt32;
                          const aHeight:TpvUInt32;
                          const aLayers:TpvUInt32;
                          const aFrameBufferHandle:TVkFrameBuffer;
                          const aFrameBufferAttachments:array of TpvVulkanFrameBufferAttachment;
                          const aDoDestroy:boolean=true;
                          const aDoDestroyAttachments:boolean=true); reintroduce; overload;
       destructor Destroy; override;
       function AddAttachment(const aFrameBufferAttachment:TpvVulkanFrameBufferAttachment):TpvInt32;
       procedure Initialize;
       property Attachments[const aIndex:TpvInt32]:TpvVulkanFrameBufferAttachment read GetFrameBufferAttachment; default;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkFrameBuffer read fFrameBufferHandle;
       property CountAttachments:TpvInt32 read fCountFrameBufferAttachments;
       property RenderPass:TpvVulkanRenderPass read fRenderPass;
       property Width:TpvUInt32 read fWidth;
       property Height:TpvUInt32 read fHeight;
       property Layers:TpvUInt32 read fLayers;
     end;

     TpvVulkanSwapChainImages=array of TpvVulkanImage;

     PpvVulkanSwapChainScreenshot=^TpvVulkanSwapChainScreenshot;
     TpvVulkanSwapChainScreenshot=record
      Width:TpvInt32;
      Height:TpvInt32;
      Data:TVkUInt8Array;
     end;

     TpvVulkanSwapChain=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fSurface:TpvVulkanSurface;
       fSwapChainHandle:TVkSwapChainKHR;
       fQueueFamilyIndices:TpvVulkanQueueFamilyIndices;
       fCountQueueFamilyIndices:TpvInt32;
       fImageFormat:TVkFormat;
       fImageColorSpace:TVkColorSpaceKHR;
       fImages:TpvVulkanSwapChainImages;
       fPresentMode:TVkPresentModeKHR;
       fPreviousImageIndex:TpvUInt32;
       fCurrentImageIndex:TpvUInt32;
       fCountImages:TpvUInt32;
       fWidth:TpvInt32;
       fHeight:TpvInt32;
       function GetImage(const aImageIndex:TpvInt32):TpvVulkanImage;
       function GetPreviousImage:TpvVulkanImage;
       function GetCurrentImage:TpvVulkanImage;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aSurface:TpvVulkanSurface;
                          const aOldSwapChain:TpvVulkanSwapChain=nil;
                          const aDesiredImageWidth:TpvUInt32=0;
                          const aDesiredImageHeight:TpvUInt32=0;
                          const aDesiredImageCount:TpvUInt32=2;
                          const aImageArrayLayers:TpvUInt32=1;
                          const aImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                          const aImageColorSpace:TVkColorSpaceKHR=VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
                          const aImageUsage:TVkImageUsageFlags=TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
                          const aImageSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                          const aQueueFamilyIndices:TVkUInt32List=nil;
                          const aCompositeAlpha:TVkCompositeAlphaFlagBitsKHR=VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
                          const aPresentMode:TVkPresentModeKHR=VK_PRESENT_MODE_MAILBOX_KHR;
                          const aClipped:boolean=true;
                          const aDesiredTransform:TVkSurfaceTransformFlagsKHR=TVkSurfaceTransformFlagsKHR($ffffffff);
                          const aSRGB:boolean=false);
       destructor Destroy; override;
       function QueuePresent(const aQueue:TpvVulkanQueue;const aSemaphore:TpvVulkanSemaphore=nil):TVkResult;
       function AcquireNextImage(const aSemaphore:TpvVulkanSemaphore=nil;const aFence:TpvVulkanFence=nil;const aTimeOut:TpvUInt64=TpvUInt64(high(TpvUInt64))):TVkResult;
       procedure GetScreenshot(out aScreenshot:TpvVulkanSwapChainScreenshot;const aSwapChainImage:TpvVulkanImage=nil);
       procedure SaveScreenshotAsJPEGToStream(const aStream:TStream;const aSwapChainImage:TpvVulkanImage=nil;const aQuality:TpvInt32=95);
       procedure SaveScreenshotAsPNGToStream(const aStream:TStream;const aSwapChainImage:TpvVulkanImage=nil);
       property Images[const aImageIndex:TpvInt32]:TpvVulkanImage read GetImage; default;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Surface:TpvVulkanSurface read fSurface;
       property Handle:TVkSwapChainKHR read fSwapChainHandle;
       property ImageFormat:TVkFormat read fImageFormat;
       property ImageColorSpace:TVkColorSpaceKHR read fImageColorSpace;
       property PresentMode:TVkPresentModeKHR read fPresentMode;
       property PreviousImageIndex:TpvUInt32 read fPreviousImageIndex;
       property CurrentImageIndex:TpvUInt32 read fCurrentImageIndex;
       property CountImages:TpvUInt32 read fCountImages;
       property PreviousImage:TpvVulkanImage read GetPreviousImage;
       property CurrentImage:TpvVulkanImage read GetCurrentImage;
       property Width:TpvInt32 read fWidth;
       property Height:TpvInt32 read fHeight;
     end;

     TpvVulkanRenderTarget=class(TpvVulkanObject)
      private
      protected
       function GetRenderPass:TpvVulkanRenderPass; virtual; abstract;
       function GetFrameBuffer:TpvVulkanFrameBuffer; virtual; abstract;
      public
      published
       property RenderPass:TpvVulkanRenderPass read GetRenderPass;
       property FrameBuffer:TpvVulkanFrameBuffer read GetFrameBuffer;
     end;

     TpvVulkanSwapChainSimpleDirectRenderTargetFrameBuffers=array of TpvVulkanFrameBuffer;

     TpvVulkanSwapChainSimpleDirectRenderTarget=class(TpvVulkanRenderTarget)
      private
       fDevice:TpvVulkanDevice;
       fSwapChain:TpvVulkanSwapChain;
       fDepthImageFormat:TVkFormat;
       fDepthFrameBufferAttachment:TpvVulkanFrameBufferAttachment;
       fFrameBufferColorAttachments:TpvVulkanFrameBufferAttachments;
       fFrameBuffers:TpvVulkanSwapChainSimpleDirectRenderTargetFrameBuffers;
       fRenderPass:TpvVulkanRenderPass;
      protected
       function GetRenderPass:TpvVulkanRenderPass; override;
       function GetFrameBuffer:TpvVulkanFrameBuffer; override;
       function GetFrameBufferAtIndex(const aIndex:TpvInt32):TpvVulkanFrameBuffer;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aSwapChain:TpvVulkanSwapChain;
                          const aPresentQueue:TpvVulkanQueue;
                          const aPresentCommandBuffer:TpvVulkanCommandBuffer;
                          const aPresentCommandBufferFence:TpvVulkanFence;
                          const aGraphicsQueue:TpvVulkanQueue;
                          const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                          const aGraphicsCommandBufferFence:TpvVulkanFence;
                          const aDepthImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                          const aDepthImageFormatWithStencil:boolean=false;
                          const aClear:boolean=true);
       destructor Destroy; override;
       property FrameBuffers[const aIndex:TpvInt32]:TpvVulkanFrameBuffer read GetFrameBufferAtIndex;
      published
       property Device:TpvVulkanDevice read fDevice;
       property SwapChain:TpvVulkanSwapChain read fSwapChain;
       property DepthImageFormat:TVkFormat read fDepthImageFormat;
     end;

     PpvVulkanShaderModuleVariableStorageClass=^TpvVulkanShaderModuleVariableStorageClass;
     TpvVulkanShaderModuleVariableStorageClass=
      (      
       vsmcscUniformConstant=0,
       vsmcscInput=1,
       vsmcscUniform=2,
       vsmcscOutput=3,
       vsmcscWorkgroup=4,
       vsmcscCrossWorkgroup=5,
       vsmcscPrivate=6,
       vsmcscFunction=7,
       vsmcscGeneric=8,
       vsmcscPushConstant=9,
       vsmcscAtomicCounter=10,
       vsmcscImage=11,
       vsmcscStorageBuffer=12,
       vsmcscMax=$7fffffff
      );

     PpvVulkanShaderModuleVariable=^TpvVulkanShaderModuleVariable;
     TpvVulkanShaderModuleVariable={$ifdef HAS_ADVANCED_RECORDS}record{$else}object{$endif}
      private
       fDebugName:TVkCharString;
       fName:TpvInt32;
       fLocation:TpvInt32;
       fBinding:TpvInt32;
       fDescriptorSet:TpvInt32;
       fInstruction:TpvInt32;
       fStorageClass:TpvVulkanShaderModuleVariableStorageClass;
      public
       property DebugName:TVkCharString read fDebugName;                                 // The name of the variable
       property Name:TpvInt32 read fName;                                                // The internal name (integer) of the variable
       property Location:TpvInt32 read fLocation;                                        // The location in the binding
       property Binding:TpvInt32 read fBinding;                                          // The binding in the descriptor set or I/O channel
       property DescriptorSet:TpvInt32 read fDescriptorSet;                              // The descriptor set (for uniforms)
       property Instruction:TpvInt32 read fInstruction;                                  // The instruction index
       property StorageClass:TpvVulkanShaderModuleVariableStorageClass read fStorageClass; // Storage class of the variable
     end;

     TpvVulkanShaderModuleVariables=array of TpvVulkanShaderModuleVariable;

     TpvVulkanShaderModule=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fShaderModuleHandle:TVkShaderModule;
       fData:PVkVoid;
       fDataAligned:PVkVoid;
       fDataSize:TVkSize;
       procedure Load;
      public
       constructor Create(const aDevice:TpvVulkanDevice;const aData;const aDataSize:TVkSize); overload;
       constructor Create(const aDevice:TpvVulkanDevice;const aStream:TStream); overload;
       constructor Create(const aDevice:TpvVulkanDevice;const aFileName:string); overload;
       destructor Destroy; override;
       function GetVariables:TpvVulkanShaderModuleVariables;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkShaderModule read fShaderModuleHandle;
     end;

     TpvVulkanShaderModules=array of TpvVulkanShaderModule;

     TpvVulkanDescriptorPool=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fDescriptorPoolHandle:TVkDescriptorPool;
       fDescriptorPoolSizes:TVkDescriptorPoolSizeArray;
       fCountDescriptorPoolSizes:TpvInt32;
       fFlags:TVkDescriptorPoolCreateFlags;
       fMaxSets:TpvUInt32;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aFlags:TVkDescriptorPoolCreateFlags;
                          const aMaxSets:TpvUInt32);
       destructor Destroy; override;
       function AddDescriptorPoolSize(const aType:TVkDescriptorType;const aDescriptorCount:TpvUInt32):TpvInt32;
       procedure Initialize;
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkDescriptorPool read fDescriptorPoolHandle;
     end;

     TpvVulkanDescriptorSetLayoutBinding=class(TpvVulkanObject)
      private                     
       fDescriptorSetLayoutBinding:TVkDescriptorSetLayoutBinding;
       fImmutableSamplers:TVkSamplerArray;
       fCountImmutableSamplers:TpvInt32;
       function GetBinding:TpvUInt32;
       procedure SetBinding(const aBinding:TpvUInt32);
       function GetDescriptorType:TVkDescriptorType;
       procedure SetDescriptorType(const aDescriptorType:TVkDescriptorType);
       function GetDescriptorCount:TpvUInt32;
       procedure SetDescriptorCount(const aDescriptorCount:TpvUInt32);
       function GetStageFlags:TVkShaderStageFlags;
       procedure SetStageFlags(const aStageFlags:TVkShaderStageFlags);
      public
       constructor Create(const aBinding:TpvUInt32;
                          const aDescriptorType:TVkDescriptorType;
                          const aDescriptorCount:TpvUInt32;
                          const aStageFlags:TVkShaderStageFlags);
       destructor Destroy; override;
       procedure AddImmutableSampler(const aImmutableSampler:TpvVulkanSampler);
       procedure AddImmutableSamplers(const aImmutableSamplers:array of TpvVulkanSampler);
       procedure Initialize;
      published
       property Binding:TpvUInt32 read GetBinding write SetBinding;
       property DescriptorType:TVkDescriptorType read GetDescriptorType write SetDescriptorType;
       property DescriptorCount:TpvUInt32 read GetDescriptorCount write SetDescriptorCount;
       property StageFlags:TVkShaderStageFlags read GetStageFlags write SetStageFlags;
     end;

     TpvVulkanDescriptorSetLayout=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fDescriptorSetLayoutHandle:TVkDescriptorSetLayout;
       fDescriptorSetLayoutBindingList:TpvVulkanObjectList;
       fDescriptorSetLayoutBindingArray:TVkDescriptorSetLayoutBindingArray;
      public
       constructor Create(const aDevice:TpvVulkanDevice);
       destructor Destroy; override;
       procedure AddBinding(const aBinding:TpvUInt32;
                            const aDescriptorType:TVkDescriptorType;
                            const aDescriptorCount:TpvUInt32;
                            const aStageFlags:TVkShaderStageFlags;
                            const aImmutableSamplers:array of TpvVulkanSampler);
       procedure Initialize;
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkDescriptorSetLayout read fDescriptorSetLayoutHandle;
     end;

     PpvVulkanDescriptorSetWriteDescriptorSetMetaData=^TpvVulkanDescriptorSetWriteDescriptorSetMetaData;
     TpvVulkanDescriptorSetWriteDescriptorSetMetaData=record
      ImageInfo:array of TVkDescriptorImageInfo;
      BufferInfo:array of TVkDescriptorBufferInfo;
      TexelBufferView:array of TVkBufferView;
     end;

     TpvVulkanDescriptorSetWriteDescriptorSetMetaDataArray=array of TpvVulkanDescriptorSetWriteDescriptorSetMetaData;

     TpvVulkanDescriptorSet=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fDescriptorPool:TpvVulkanDescriptorPool;
       fDescriptorSetLayout:TpvVulkanDescriptorSetLayout;
       fDescriptorSetHandle:TVkDescriptorSet;
       fDescriptorSetAllocateInfo:TVkDescriptorSetAllocateInfo;
       fCopyDescriptorSetQueue:TVkCopyDescriptorSetArray;
       fCopyDescriptorSetQueueSize:TpvInt32;
       fWriteDescriptorSetQueue:TVkWriteDescriptorSetArray;
       fWriteDescriptorSetQueueMetaData:TpvVulkanDescriptorSetWriteDescriptorSetMetaDataArray;
       fWriteDescriptorSetQueueSize:TpvInt32;
      public
       constructor Create(const aDescriptorPool:TpvVulkanDescriptorPool;
                          const aDescriptorSetLayout:TpvVulkanDescriptorSetLayout);
       destructor Destroy; override;
       class function Allocate(const aDescriptorPool:TpvVulkanDescriptorPool;
                               const aDescriptorSetLayouts:array of TpvVulkanDescriptorSetLayout):TpvVulkanObjectList;
       procedure CopyFromDescriptorSet(const aSourceDescriptorSet:TpvVulkanDescriptorSet;
                                       const aSourceBinding:TpvUInt32;
                                       const aSourceArrayElement:TpvUInt32;
                                       const aDestinationBinding:TpvUInt32;
                                       const aDestinationArrayElement:TpvUInt32;
                                       const aDescriptorCount:TpvUInt32;
                                       const aDoInstant:boolean=false);
       procedure WriteToDescriptorSet(const aDestinationBinding:TpvUInt32;
                                      const aDestinationArrayElement:TpvUInt32;
                                      const aDescriptorCount:TpvUInt32;
                                      const aDescriptorType:TVkDescriptorType;
                                      const aImageInfo:array of TVkDescriptorImageInfo;
                                      const aBufferInfo:array of TVkDescriptorBufferInfo;
                                      const aTexelBufferView:array of TVkBufferView;
                                      const aDoInstant:boolean=false);
       procedure Flush;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkDescriptorSet read fDescriptorSetHandle;
       property DescriptorPool:TpvVulkanDescriptorPool read fDescriptorPool;
       property DescriptorSetLayout:TpvVulkanDescriptorSetLayout read fDescriptorSetLayout;
     end;

     TpvVulkanPipelineLayout=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fPipelineLayoutHandle:TVkPipelineLayout;
       fDescriptorSetLayouts:TVkDescriptorSetLayoutArray;
       fCountDescriptorSetLayouts:TpvInt32;
       fPushConstantRanges:TVkPushConstantRangeArray;
       fCountPushConstantRanges:TpvInt32;
      public
       constructor Create(const aDevice:TpvVulkanDevice);
       destructor Destroy; override;
       function AddDescriptorSetLayout(const aDescriptorSetLayout:TVkDescriptorSetLayout):TpvInt32; overload;
       function AddDescriptorSetLayout(const aDescriptorSetLayout:TpvVulkanDescriptorSetLayout):TpvInt32; overload;
       function AddDescriptorSetLayouts(const aDescriptorSetLayouts:array of TVkDescriptorSetLayout):TpvInt32; overload;
       function AddDescriptorSetLayouts(const aDescriptorSetLayouts:array of TpvVulkanDescriptorSetLayout):TpvInt32; overload;
       function AddPushConstantRange(const aPushConstantRange:TVkPushConstantRange):TpvInt32; overload;
       function AddPushConstantRange(const aStageFlags:TVkShaderStageFlags;const aOffset,aSize:TpvUInt32):TpvInt32; overload;
       function AddPushConstantRanges(const aPushConstantRanges:array of TVkPushConstantRange):TpvInt32;
       procedure Initialize;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkPipelineLayout read fPipelineLayoutHandle;
     end;

     TpvVulkanPipelineShaderStage=class(TpvVulkanObject)
      private
       fPipelineShaderStageCreateInfo:TVkPipelineShaderStageCreateInfo;
       fPointerToPipelineShaderStageCreateInfo:PVkPipelineShaderStageCreateInfo;
       fName:TVkCharString;
       fSpecializationInfo:PVkSpecializationInfo;
       fDoCopyAndDoFree:boolean;
       fSpecializationMapEntries:TVkSpecializationMapEntryArray;
       fCountSpecializationMapEntries:TpvInt32;
       fInitialized:boolean;
       procedure AllocateSpecializationInfo;
      public
       constructor Create(const aStage:TVkShaderStageFlagBits;
                          const aModule:TpvVulkanShaderModule;
                          const aName:TVkCharString);
       destructor Destroy; override;
       procedure AddSpecializationDataFromMemory(const aData:TpvPointer;const aDataSize:TVkSize;const aDoCopyAndDoFree:boolean=true);
       procedure AddSpecializationDataFromStream(const aStream:TStream);
       procedure AddSpecializationDataFromFile(const aFileName:string);
       function AddSpecializationMapEntry(const aSpecializationMapEntry:TVkSpecializationMapEntry):TpvInt32; overload;
       function AddSpecializationMapEntry(const aConstantID,aOffset:TpvUInt32;const aSize:TVkSize):TpvInt32; overload;
       function AddSpecializationMapEntries(const aSpecializationMapEntries:array of TVkSpecializationMapEntry):TpvInt32;
       procedure Initialize;
       property PipelineShaderStageCreateInfo:PVkPipelineShaderStageCreateInfo read fPointerToPipelineShaderStageCreateInfo;
      published
     end;

     TpvVulkanPipelineCache=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fPipelineCacheHandle:TVkPipelineCache;
      public
       constructor Create(const aDevice:TpvVulkanDevice;const aInitialData:TpvPointer=nil;const aInitialDataSize:TVkSize=0);
       constructor CreateFromMemory(const aDevice:TpvVulkanDevice;const aInitialData:TpvPointer;const aInitialDataSize:TVkSize);
       constructor CreateFromStream(const aDevice:TpvVulkanDevice;const aStream:TStream);
       constructor CreateFromFile(const aDevice:TpvVulkanDevice;const aFileName:string);
       destructor Destroy; override;
       procedure SaveToStream(const aStream:TStream);
       procedure SaveToFile(const aFileName:string);
       procedure Merge(const aSourcePipelineCache:TpvVulkanPipelineCache); overload;
       procedure Merge(const aSourcePipelineCaches:array of TpvVulkanPipelineCache); overload;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkPipelineCache read fPipelineCacheHandle;
     end;

     TpvVulkanPipeline=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fPipelineHandle:TVkPipeline;
      public
       constructor Create(const aDevice:TpvVulkanDevice);
       destructor Destroy; override;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Handle:TVkPipeline read fPipelineHandle;
     end;

     TpvVulkanComputePipeline=class(TpvVulkanPipeline)
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aCache:TpvVulkanPipelineCache;
                          const aFlags:TVkPipelineCreateFlags;
                          const aStage:TpvVulkanPipelineShaderStage;
                          const aLayout:TpvVulkanPipelineLayout;
                          const aBasePipelineHandle:TpvVulkanPipeline;
                          const aBasePipelineIndex:TpvInt32); reintroduce;
     end;

     TpvVulkanPipelineState=class(TpvVulkanObject)
      public
       constructor Create;
       destructor Destroy; override;
     end;

     TpvVulkanPipelineVertexInputState=class(TpvVulkanPipelineState)
      private
       fVertexInputStateCreateInfo:TVkPipelineVertexInputStateCreateInfo;
       fPointerToVertexInputStateCreateInfo:PVkPipelineVertexInputStateCreateInfo;
       fVertexInputBindingDescriptions:TVkVertexInputBindingDescriptionArray;
       fCountVertexInputBindingDescriptions:TpvInt32;
       fVertexInputAttributeDescriptions:TVkVertexInputAttributeDescriptionArray;
       fCountVertexInputAttributeDescriptions:TpvInt32;
       function GetVertexInputBindingDescription(const aIndex:TpvInt32):PVkVertexInputBindingDescription;
       function GetVertexInputAttributeDescription(const aIndex:TpvInt32):PVkVertexInputAttributeDescription;
       procedure SetCountVertexInputBindingDescriptions(const aNewCount:TpvInt32);
       procedure SetCountVertexInputAttributeDescriptions(const aNewCount:TpvInt32);
       procedure Initialize;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineVertexInputState);
       function AddVertexInputBindingDescription(const aVertexInputBindingDescription:TVkVertexInputBindingDescription):TpvInt32; overload;
       function AddVertexInputBindingDescription(const aBinding,aStride:TpvUInt32;const aInputRate:TVkVertexInputRate):TpvInt32; overload;
       function AddVertexInputBindingDescriptions(const aVertexInputBindingDescriptions:array of TVkVertexInputBindingDescription):TpvInt32;
       function AddVertexInputAttributeDescription(const aVertexInputAttributeDescription:TVkVertexInputAttributeDescription):TpvInt32; overload;
       function AddVertexInputAttributeDescription(const aLocation,aBinding:TpvUInt32;const aFormat:TVkFormat;const aOffset:TpvUInt32):TpvInt32; overload;
       function AddVertexInputAttributeDescriptions(const aVertexInputAttributeDescriptions:array of TVkVertexInputAttributeDescription):TpvInt32;
       property VertexInputStateCreateInfo:PVkPipelineVertexInputStateCreateInfo read fPointerToVertexInputStateCreateInfo;
       property VertexInputBindingDescriptions[const aIndex:TpvInt32]:PVkVertexInputBindingDescription read GetVertexInputBindingDescription;
       property VertexInputAttributeDescriptions[const aIndex:TpvInt32]:PVkVertexInputAttributeDescription read GetVertexInputAttributeDescription;
      published
       property CountVertexInputBindingDescriptions:TpvInt32 read fCountVertexInputBindingDescriptions write SetCountVertexInputBindingDescriptions;
       property CountVertexInputAttributeDescriptions:TpvInt32 read fCountVertexInputAttributeDescriptions write SetCountVertexInputAttributeDescriptions;
     end;

     TpvVulkanPipelineInputAssemblyState=class(TpvVulkanPipelineState)
      private
       fInputAssemblyStateCreateInfo:TVkPipelineInputAssemblyStateCreateInfo;
       fPointerToInputAssemblyStateCreateInfo:PVkPipelineInputAssemblyStateCreateInfo;
       function GetTopology:TVkPrimitiveTopology;
       procedure SetTopology(const aNewValue:TVkPrimitiveTopology);
       function GetPrimitiveRestartEnable:boolean;
       procedure SetPrimitiveRestartEnable(const aNewValue:boolean);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineInputAssemblyState);
       procedure SetInputAssemblyState(const aTopology:TVkPrimitiveTopology;const aPrimitiveRestartEnable:boolean);
       property InputAssemblyStateCreateInfo:PVkPipelineInputAssemblyStateCreateInfo read fPointerToInputAssemblyStateCreateInfo;
      published
       property Topology:TVkPrimitiveTopology read GetTopology write SetTopology;
       property PrimitiveRestartEnable:boolean read GetPrimitiveRestartEnable write SetPrimitiveRestartEnable;
     end;

     TpvVulkanPipelineTessellationState=class(TpvVulkanPipelineState)
      private
       fTessellationStateCreateInfo:TVkPipelineTessellationStateCreateInfo;
       fPointerToTessellationStateCreateInfo:PVkPipelineTessellationStateCreateInfo;
       function GetPatchControlPoints:TpvUInt32;
       procedure SetPatchControlPoints(const aNewValue:TpvUInt32);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineTessellationState);
       procedure SetTessellationState(const aPatchControlPoints:TpvUInt32);
       property TessellationStateCreateInfo:PVkPipelineTessellationStateCreateInfo read fPointerToTessellationStateCreateInfo;
      published
       property PatchControlPoints:TpvUInt32 read GetPatchControlPoints write SetPatchControlPoints;
     end;

     TpvVulkanPipelineViewPortState=class(TpvVulkanPipelineState)
      private
       fViewportStateCreateInfo:TVkPipelineViewportStateCreateInfo;
       fPointerToViewportStateCreateInfo:PVkPipelineViewportStateCreateInfo;
       fViewPorts:TVkViewportArray;
       fCountViewPorts:TpvInt32;
       fDynamicViewPorts:boolean;
       fScissors:TVkRect2DArray;
       fCountScissors:TpvInt32;
       fDynamicScissors:boolean;
       function GetViewPort(const aIndex:TpvInt32):PVkViewport;
       function GetScissor(const aIndex:TpvInt32):PVkRect2D;
       procedure SetCountViewPorts(const aNewCount:TpvInt32);
       procedure SetCountScissors(const aNewCount:TpvInt32);
       procedure Initialize;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineViewPortState);
       function AddViewPort(const aViewPort:TVkViewport):TpvInt32; overload;
       function AddViewPort(const pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth:TpvFloat):TpvInt32; overload;
       function AddViewPorts(const aViewPorts:array of TVkViewport):TpvInt32; overload;
       function AddScissor(const aScissor:TVkRect2D):TpvInt32; overload;
       function AddScissor(const pX,pY:TpvInt32;const aWidth,aHeight:TpvUInt32):TpvInt32; overload;
       function AddScissors(const aScissors:array of TVkRect2D):TpvInt32; overload;
       property ViewportStateCreateInfo:PVkPipelineViewportStateCreateInfo read fPointerToViewportStateCreateInfo;
       property ViewPorts[const aIndex:TpvInt32]:PVkViewport read GetViewPort;
       property Scissors[const aIndex:TpvInt32]:PVkRect2D read GetScissor;
      published
       property CountViewPorts:TpvInt32 read fCountViewPorts write SetCountViewPorts;
       property DynamicViewPorts:boolean read fDynamicViewPorts write fDynamicViewPorts;
       property CountScissors:TpvInt32 read fCountScissors write SetCountScissors;
       property DynamicScissors:boolean read fDynamicScissors write fDynamicScissors;
     end;

     TpvVulkanPipelineRasterizationState=class(TpvVulkanPipelineState)
      private
       fRasterizationStateCreateInfo:TVkPipelineRasterizationStateCreateInfo;
       fPointerToRasterizationStateCreateInfo:PVkPipelineRasterizationStateCreateInfo;
       function GetDepthClampEnable:boolean;
       procedure SetDepthClampEnable(const aNewValue:boolean);
       function GetRasterizerDiscardEnable:boolean;
       procedure SetRasterizerDiscardEnable(const aNewValue:boolean);
       function GetPolygonMode:TVkPolygonMode;
       procedure SetPolygonMode(const aNewValue:TVkPolygonMode);
       function GetCullMode:TVkCullModeFlags;
       procedure SetCullMode(const aNewValue:TVkCullModeFlags);
       function GetFrontFace:TVkFrontFace;
       procedure SetFrontFace(const aNewValue:TVkFrontFace);
       function GetDepthBiasEnable:boolean;
       procedure SetDepthBiasEnable(const aNewValue:boolean);
       function GetDepthBiasConstantFactor:TpvFloat;
       procedure SetDepthBiasConstantFactor(const aNewValue:TpvFloat);
       function GetDepthBiasClamp:TpvFloat;
       procedure SetDepthBiasClamp(const aNewValue:TpvFloat);
       function GetDepthBiasSlopeFactor:TpvFloat;
       procedure SetDepthBiasSlopeFactor(const aNewValue:TpvFloat);
       function GetLineWidth:TpvFloat;
       procedure SetLineWidth(const aNewValue:TpvFloat);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineRasterizationState);
       procedure SetRasterizationState(const aDepthClampEnable:boolean;
                                       const aRasterizerDiscardEnable:boolean;
                                       const aPolygonMode:TVkPolygonMode;
                                       const aCullMode:TVkCullModeFlags;
                                       const aFrontFace:TVkFrontFace;
                                       const aDepthBiasEnable:boolean;
                                       const aDepthBiasConstantFactor:TpvFloat;
                                       const aDepthBiasClamp:TpvFloat;
                                       const aDepthBiasSlopeFactor:TpvFloat;
                                       const aLineWidth:TpvFloat);
       property RasterizationStateCreateInfo:PVkPipelineRasterizationStateCreateInfo read fPointerToRasterizationStateCreateInfo;
      published
       property DepthClampEnable:boolean read GetDepthClampEnable write SetDepthClampEnable;
       property RasterizerDiscardEnable:boolean read GetRasterizerDiscardEnable write SetRasterizerDiscardEnable;
       property PolygonMode:TVkPolygonMode read GetPolygonMode write SetPolygonMode;
       property CullMode:TVkCullModeFlags read GetCullMode write SetCullMode;
       property FrontFace:TVkFrontFace read GetFrontFace write SetFrontFace;
       property DepthBiasEnable:boolean read GetDepthBiasEnable write SetDepthBiasEnable;
       property DepthBiasConstantFactor:TpvFloat read GetDepthBiasConstantFactor write SetDepthBiasConstantFactor;
       property DepthBiasClamp:TpvFloat read GetDepthBiasClamp write SetDepthBiasClamp;
       property DepthBiasSlopeFactor:TpvFloat read GetDepthBiasSlopeFactor write SetDepthBiasSlopeFactor;
       property LineWidth:TpvFloat read GetLineWidth write SetLineWidth;
     end;

     TpvVulkanPipelineMultisampleState=class(TpvVulkanPipelineState)
      private
       fMultisampleStateCreateInfo:TVkPipelineMultisampleStateCreateInfo;
       fPointerToMultisampleStateCreateInfo:PVkPipelineMultisampleStateCreateInfo;
       fSampleMasks:TVkSampleMaskArray;
       fCountSampleMasks:TpvInt32;
       function GetRasterizationSamples:TVkSampleCountFlagBits;
       procedure SetRasterizationSamples(const aNewValue:TVkSampleCountFlagBits);
       function GetSampleShadingEnable:boolean;
       procedure SetSampleShadingEnable(const aNewValue:boolean);
       function GetSampleMask(const aIndex:TpvInt32):TVkSampleMask;
       procedure SetSampleMask(const aIndex:TpvInt32;const aNewValue:TVkSampleMask);
       procedure SetCountSampleMasks(const aNewCount:TpvInt32);
       function GetMinSampleShading:TpvFloat;
       procedure SetMinSampleShading(const aNewValue:TpvFloat);
       function GetAlphaToCoverageEnable:boolean;
       procedure SetAlphaToCoverageEnable(const aNewValue:boolean);
       function GetAlphaToOneEnable:boolean;
       procedure SetAlphaToOneEnable(const aNewValue:boolean);
       procedure Initialize;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineMultisampleState);
       function AddSampleMask(const aSampleMask:TVkSampleMask):TpvInt32;
       function AddSampleMasks(const aSampleMasks:array of TVkSampleMask):TpvInt32;
       procedure SetMultisampleState(const aRasterizationSamples:TVkSampleCountFlagBits;
                                     const aSampleShadingEnable:boolean;
                                     const aMinSampleShading:TpvFloat;
                                     const aSampleMask:array of TVkSampleMask;
                                     const aAlphaToCoverageEnable:boolean;
                                     const aAlphaToOneEnable:boolean);
       property MultisampleStateCreateInfo:PVkPipelineMultisampleStateCreateInfo read fPointerToMultisampleStateCreateInfo;
       property SampleMasks[const aIndex:TpvInt32]:TVkSampleMask read GetSampleMask write SetSampleMask;
      published                                                                            
       property RasterizationSamples:TVkSampleCountFlagBits read GetRasterizationSamples write SetRasterizationSamples;
       property SampleShadingEnable:boolean read GetSampleShadingEnable write SetSampleShadingEnable;
       property MinSampleShading:TpvFloat read GetMinSampleShading write SetMinSampleShading;
       property CountSampleMasks:TpvInt32 read fCountSampleMasks write SetCountSampleMasks;
       property AlphaToCoverageEnable:boolean read GetAlphaToCoverageEnable write SetAlphaToCoverageEnable;
       property AlphaToOneEnable:boolean read GetAlphaToOneEnable write SetAlphaToOneEnable;
     end;

     TpvVulkanStencilOpState=class(TpvVulkanObject)
      private
       fStencilOpState:PVkStencilOpState;
       function GetFailOp:TVkStencilOp;
       procedure SetFailOp(const aNewValue:TVkStencilOp);
       function GetPassOp:TVkStencilOp;
       procedure SetPassOp(const aNewValue:TVkStencilOp);
       function GetDepthFailOp:TVkStencilOp;
       procedure SetDepthFailOp(const aNewValue:TVkStencilOp);
       function GetCompareOp:TVkCompareOp;
       procedure SetCompareOp(const aNewValue:TVkCompareOp);
       function GetCompareMask:TpvUInt32;
       procedure SetCompareMask(const aNewValue:TpvUInt32);
       function GetWriteMask:TpvUInt32;
       procedure SetWriteMask(const aNewValue:TpvUInt32);
       function GetReference:TpvUInt32;
       procedure SetReference(const aNewValue:TpvUInt32);
      public
       constructor Create(const aStencilOpState:PVkStencilOpState);
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanStencilOpState);
       property StencilOpState:PVkStencilOpState read fStencilOpState;
      published
       property FailOp:TVkStencilOp read GetFailOp write SetFailOp;
       property PassOp:TVkStencilOp read GetPassOp write SetPassOp;
       property DepthFailOp:TVkStencilOp read GetDepthFailOp write SetDepthFailOp;
       property CompareOp:TVkCompareOp read GetCompareOp write SetCompareOp;
       property CompareMask:TpvUInt32 read GetCompareMask write SetCompareMask;
       property WriteMask:TpvUInt32 read GetWriteMask write SetWriteMask;
       property Reference:TpvUInt32 read GetReference write SetReference;
     end;

     TpvVulkanPipelineDepthStencilState=class(TpvVulkanPipelineState)
      private
       fDepthStencilStateCreateInfo:TVkPipelineDepthStencilStateCreateInfo;
       fPointerToDepthStencilStateCreateInfo:PVkPipelineDepthStencilStateCreateInfo;
       fFrontStencilOpState:TpvVulkanStencilOpState;
       fBackStencilOpState:TpvVulkanStencilOpState;
       function GetDepthTestEnable:boolean;
       procedure SetDepthTestEnable(const aNewValue:boolean);
       function GetDepthWriteEnable:boolean;
       procedure SetDepthWriteEnable(const aNewValue:boolean);
       function GetDepthCompareOp:TVkCompareOp;
       procedure SetDepthCompareOp(const aNewValue:TVkCompareOp);
       function GetDepthBoundsTestEnable:boolean;
       procedure SetDepthBoundsTestEnable(const aNewValue:boolean);
       function GetStencilTestEnable:boolean;
       procedure SetStencilTestEnable(const aNewValue:boolean);
       function GetMinDepthBounds:TpvFloat;
       procedure SetMinDepthBounds(const aNewValue:TpvFloat);
       function GetMaxDepthBounds:TpvFloat;
       procedure SetMaxDepthBounds(const aNewValue:TpvFloat);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineDepthStencilState);
       procedure SetDepthStencilState(const aDepthTestEnable:boolean;
                                      const aDepthWriteEnable:boolean;
                                      const aDepthCompareOp:TVkCompareOp;
                                      const aDepthBoundsTestEnable:boolean;
                                      const aStencilTestEnable:boolean;
                                      const aFront:TVkStencilOpState;
                                      const aBack:TVkStencilOpState;
                                      const aMinDepthBounds:TpvFloat;
                                      const aMaxDepthBounds:TpvFloat);
       property DepthStencilStateCreateInfo:PVkPipelineDepthStencilStateCreateInfo read fPointerToDepthStencilStateCreateInfo;
      published
       property DepthTestEnable:boolean read GetDepthTestEnable write SetDepthTestEnable;
       property DepthWriteEnable:boolean read GetDepthWriteEnable write SetDepthWriteEnable;
       property DepthCompareOp:TVkCompareOp read GetDepthCompareOp write SetDepthCompareOp;
       property DepthBoundsTestEnable:boolean read GetDepthBoundsTestEnable write SetDepthBoundsTestEnable;
       property StencilTestEnable:boolean read GetStencilTestEnable write SetStencilTestEnable;
       property Front:TpvVulkanStencilOpState read fFrontStencilOpState;
       property Back:TpvVulkanStencilOpState read fBackStencilOpState;
       property MinDepthBounds:TpvFloat read GetMinDepthBounds write SetMinDepthBounds;
       property MaxDepthBounds:TpvFloat read GetMaxDepthBounds write SetMaxDepthBounds;
     end;

     TpvVulkanPipelineColorBlendState=class(TpvVulkanPipelineState)
      private
       fColorBlendStateCreateInfo:TVkPipelineColorBlendStateCreateInfo;
       fPointerToColorBlendStateCreateInfo:PVkPipelineColorBlendStateCreateInfo;
       fColorBlendAttachmentStates:TVkPipelineColorBlendAttachmentStateArray;
       fCountColorBlendAttachmentStates:TpvInt32;
       function GetLogicOpEnable:boolean;
       procedure SetLogicOpEnable(const aNewValue:boolean);
       function GetLogicOp:TVkLogicOp;
       procedure SetLogicOp(const aNewValue:TVkLogicOp);
       procedure SetCountColorBlendAttachmentStates(const aNewCount:TpvInt32);
       function GetColorBlendAttachmentState(const aIndex:TpvInt32):PVkPipelineColorBlendAttachmentState;
       function GetBlendConstant(const aIndex:TpvInt32):TpvFloat;
       procedure SetBlendConstant(const aIndex:TpvInt32;const aNewValue:TpvFloat);
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineColorBlendState);
       procedure SetColorBlendState(const aLogicOpEnable:boolean;
                                    const aLogicOp:TVkLogicOp;
                                    const aBlendConstants:array of TpvFloat);
       function AddColorBlendAttachmentState(const aColorBlendAttachmentState:TVkPipelineColorBlendAttachmentState):TpvInt32; overload;
       function AddColorBlendAttachmentState(const aBlendEnable:boolean;
                                             const aSrcColorBlendFactor:TVkBlendFactor;
                                             const aDstColorBlendFactor:TVkBlendFactor;
                                             const aColorBlendOp:TVkBlendOp;
                                             const aSrcAlphaBlendFactor:TVkBlendFactor;
                                             const aDstAlphaBlendFactor:TVkBlendFactor;
                                             const aAlphaBlendOp:TVkBlendOp;
                                             const aColorWriteMask:TVkColorComponentFlags):TpvInt32; overload;
       function AddColorBlendAttachmentStates(const aColorBlendAttachmentStates:array of TVkPipelineColorBlendAttachmentState):TpvInt32;
       procedure Initialize;
       property ColorBlendStateCreateInfo:PVkPipelineColorBlendStateCreateInfo read fPointerToColorBlendStateCreateInfo;
       property ColorBlendAttachmentStates[const aIndex:TpvInt32]:PVkPipelineColorBlendAttachmentState read GetColorBlendAttachmentState;
       property BlendConstants[const aIndex:TpvInt32]:TpvFloat read GetBlendConstant write SetBlendConstant;
      published
       property LogicOpEnable:boolean read GetLogicOpEnable write SetLogicOpEnable;
       property LogicOp:TVkLogicOp read GetLogicOp write SetLogicOp;
       property CountColorBlendAttachmentStates:TpvInt32 read fCountColorBlendAttachmentStates write SetCountColorBlendAttachmentStates;
     end;

     TpvVulkanPipelineDynamicState=class(TpvVulkanPipelineState)
      private
       fDynamicStateCreateInfo:TVkPipelineDynamicStateCreateInfo;
       fPointerToDynamicStateCreateInfo:PVkPipelineDynamicStateCreateInfo;
       fDynamicStates:TVkDynamicStateArray;
       fCountDynamicStates:TpvInt32;
       function GetDynamicState(const aIndex:TpvInt32):PVkDynamicState;
       procedure SetCountDynamicStates(const aNewCount:TpvInt32);
       procedure Initialize;
      public
       constructor Create;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanPipelineDynamicState);
       function AddDynamicState(const aDynamicState:TVkDynamicState):TpvInt32;
       function AddDynamicStates(const aDynamicStates:array of TVkDynamicState):TpvInt32;
       property DynamicStateStateCreateInfo:PVkPipelineDynamicStateCreateInfo read fPointerToDynamicStateCreateInfo;
       property DynamicStates[const aIndex:TpvInt32]:PVkDynamicState read GetDynamicState;
      published
       property CountDynamicStates:TpvInt32 read fCountDynamicStates write SetCountDynamicStates;
     end;

     TpvVulkanGraphicsPipelineConstructor=class(TpvVulkanPipeline)
      private
       fGraphicsPipelineCreateInfo:TVkGraphicsPipelineCreateInfo;
       fStages:TVkPipelineShaderStageCreateInfoArray;
       fCountStages:TpvInt32;
       fVertexInputState:TpvVulkanPipelineVertexInputState;
       fInputAssemblyState:TpvVulkanPipelineInputAssemblyState;
       fTessellationState:TpvVulkanPipelineTessellationState;
       fViewPortState:TpvVulkanPipelineViewPortState;
       fRasterizationState:TpvVulkanPipelineRasterizationState;
       fMultisampleState:TpvVulkanPipelineMultisampleState;
       fDepthStencilState:TpvVulkanPipelineDepthStencilState;
       fColorBlendState:TpvVulkanPipelineColorBlendState;
       fDynamicState:TpvVulkanPipelineDynamicState;
       fPipelineCache:TVkPipelineCache;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aCache:TpvVulkanPipelineCache;
                          const aFlags:TVkPipelineCreateFlags;
                          const aStages:array of TpvVulkanPipelineShaderStage;
                          const aLayout:TpvVulkanPipelineLayout;
                          const aRenderPass:TpvVulkanRenderPass;
                          const aSubPass:TpvUInt32;
                          const aBasePipelineHandle:TpvVulkanPipeline;
                          const aBasePipelineIndex:TpvInt32); reintroduce;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanGraphicsPipelineConstructor);
       function AddStage(const aStage:TpvVulkanPipelineShaderStage):TpvInt32;
       function AddStages(const aStages:array of TpvVulkanPipelineShaderStage):TpvInt32;
       function AddVertexInputBindingDescription(const aVertexInputBindingDescription:TVkVertexInputBindingDescription):TpvInt32; overload;
       function AddVertexInputBindingDescription(const aBinding,aStride:TpvUInt32;const aInputRate:TVkVertexInputRate):TpvInt32; overload;
       function AddVertexInputBindingDescriptions(const aVertexInputBindingDescriptions:array of TVkVertexInputBindingDescription):TpvInt32;
       function AddVertexInputAttributeDescription(const aVertexInputAttributeDescription:TVkVertexInputAttributeDescription):TpvInt32; overload;
       function AddVertexInputAttributeDescription(const aLocation,aBinding:TpvUInt32;const aFormat:TVkFormat;const aOffset:TpvUInt32):TpvInt32; overload;
       function AddVertexInputAttributeDescriptions(const aVertexInputAttributeDescriptions:array of TVkVertexInputAttributeDescription):TpvInt32;
       procedure SetInputAssemblyState(const aTopology:TVkPrimitiveTopology;const aPrimitiveRestartEnable:boolean);
       procedure SetTessellationState(const aPatchControlPoints:TpvUInt32);
       function AddViewPort(const aViewPort:TVkViewport):TpvInt32; overload;
       function AddViewPort(const pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth:TpvFloat):TpvInt32; overload;
       function AddViewPorts(const aViewPorts:array of TVkViewport):TpvInt32; overload;
       function AddScissor(const aScissor:TVkRect2D):TpvInt32; overload;
       function AddScissor(const pX,pY:TpvInt32;const aWidth,aHeight:TpvUInt32):TpvInt32; overload;
       function AddScissors(const aScissors:array of TVkRect2D):TpvInt32; overload;
       procedure SetRasterizationState(const aDepthClampEnable:boolean;
                                       const aRasterizerDiscardEnable:boolean;
                                       const aPolygonMode:TVkPolygonMode;
                                       const aCullMode:TVkCullModeFlags;
                                       const aFrontFace:TVkFrontFace;
                                       const aDepthBiasEnable:boolean;
                                       const aDepthBiasConstantFactor:TpvFloat;
                                       const aDepthBiasClamp:TpvFloat;
                                       const aDepthBiasSlopeFactor:TpvFloat;
                                       const aLineWidth:TpvFloat);
       procedure SetMultisampleState(const aRasterizationSamples:TVkSampleCountFlagBits;
                                     const aSampleShadingEnable:boolean;
                                     const aMinSampleShading:TpvFloat;
                                     const aSampleMask:array of TVkSampleMask;
                                     const aAlphaToCoverageEnable:boolean;
                                     const aAlphaToOneEnable:boolean);
       procedure SetDepthStencilState(const aDepthTestEnable:boolean;
                                      const aDepthWriteEnable:boolean;
                                      const aDepthCompareOp:TVkCompareOp;
                                      const aDepthBoundsTestEnable:boolean;
                                      const aStencilTestEnable:boolean;
                                      const aFront:TVkStencilOpState;
                                      const aBack:TVkStencilOpState;
                                      const aMinDepthBounds:TpvFloat;
                                      const aMaxDepthBounds:TpvFloat);
       procedure SetColorBlendState(const aLogicOpEnable:boolean;
                                    const aLogicOp:TVkLogicOp;
                                    const aBlendConstants:array of TpvFloat);
       function AddColorBlendAttachmentState(const aColorBlendAttachmentState:TVkPipelineColorBlendAttachmentState):TpvInt32; overload;
       function AddColorBlendAttachmentState(const aBlendEnable:boolean;
                                             const aSrcColorBlendFactor:TVkBlendFactor;
                                             const aDstColorBlendFactor:TVkBlendFactor;
                                             const aColorBlendOp:TVkBlendOp;
                                             const aSrcAlphaBlendFactor:TVkBlendFactor;
                                             const aDstAlphaBlendFactor:TVkBlendFactor;
                                             const aAlphaBlendOp:TVkBlendOp;
                                             const aColorWriteMask:TVkColorComponentFlags):TpvInt32; overload;
       function AddColorBlendAttachmentStates(const aColorBlendAttachmentStates:array of TVkPipelineColorBlendAttachmentState):TpvInt32;
       function AddDynamicState(const aDynamicState:TVkDynamicState):TpvInt32;
       function AddDynamicStates(const aDynamicStates:array of TVkDynamicState):TpvInt32;
       procedure Initialize;
       property Stages:TVkPipelineShaderStageCreateInfoArray read fStages;
      published
       property CountStages:TpvInt32 read fCountStages;
       property VertexInputState:TpvVulkanPipelineVertexInputState read fVertexInputState;
       property InputAssemblyState:TpvVulkanPipelineInputAssemblyState read fInputAssemblyState;
       property TessellationState:TpvVulkanPipelineTessellationState read fTessellationState;
       property ViewPortState:TpvVulkanPipelineViewPortState read fViewPortState;
       property RasterizationState:TpvVulkanPipelineRasterizationState read fRasterizationState;
       property MultisampleState:TpvVulkanPipelineMultisampleState read fMultisampleState;
       property DepthStencilState:TpvVulkanPipelineDepthStencilState read fDepthStencilState;
       property ColorBlendState:TpvVulkanPipelineColorBlendState read fColorBlendState;
       property DynamicState:TpvVulkanPipelineDynamicState read fDynamicState;
     end;

     TpvVulkanGraphicsPipeline=class(TpvVulkanPipeline)
      private
       fGraphicsPipelineConstructor:TpvVulkanGraphicsPipelineConstructor;
       function GetCountStages:TpvInt32;
       function GetVertexInputState:TpvVulkanPipelineVertexInputState;
       function GetInputAssemblyState:TpvVulkanPipelineInputAssemblyState;
       function GetTessellationState:TpvVulkanPipelineTessellationState;
       function GetViewPortState:TpvVulkanPipelineViewPortState;
       function GetRasterizationState:TpvVulkanPipelineRasterizationState;
       function GetMultisampleState:TpvVulkanPipelineMultisampleState;
       function GetDepthStencilState:TpvVulkanPipelineDepthStencilState;
       function GetColorBlendState:TpvVulkanPipelineColorBlendState;
       function GetDynamicState:TpvVulkanPipelineDynamicState;
      public
       constructor Create(const aDevice:TpvVulkanDevice;
                          const aCache:TpvVulkanPipelineCache;
                          const aFlags:TVkPipelineCreateFlags;
                          const aStages:array of TpvVulkanPipelineShaderStage;
                          const aLayout:TpvVulkanPipelineLayout;
                          const aRenderPass:TpvVulkanRenderPass;
                          const aSubPass:TpvUInt32;
                          const aBasePipelineHandle:TpvVulkanPipeline;
                          const aBasePipelineIndex:TpvInt32); reintroduce;
       destructor Destroy; override;
       procedure Assign(const aFrom:TpvVulkanGraphicsPipeline);
       function AddStage(const aStage:TpvVulkanPipelineShaderStage):TpvInt32;
       function AddStages(const aStages:array of TpvVulkanPipelineShaderStage):TpvInt32;
       function AddVertexInputBindingDescription(const aVertexInputBindingDescription:TVkVertexInputBindingDescription):TpvInt32; overload;
       function AddVertexInputBindingDescription(const aBinding,aStride:TpvUInt32;const aInputRate:TVkVertexInputRate):TpvInt32; overload;
       function AddVertexInputBindingDescriptions(const aVertexInputBindingDescriptions:array of TVkVertexInputBindingDescription):TpvInt32;
       function AddVertexInputAttributeDescription(const aVertexInputAttributeDescription:TVkVertexInputAttributeDescription):TpvInt32; overload;
       function AddVertexInputAttributeDescription(const aLocation,aBinding:TpvUInt32;const aFormat:TVkFormat;const aOffset:TpvUInt32):TpvInt32; overload;
       function AddVertexInputAttributeDescriptions(const aVertexInputAttributeDescriptions:array of TVkVertexInputAttributeDescription):TpvInt32;
       procedure SetInputAssemblyState(const aTopology:TVkPrimitiveTopology;const aPrimitiveRestartEnable:boolean);
       procedure SetTessellationState(const aPatchControlPoints:TpvUInt32);
       function AddViewPort(const aViewPort:TVkViewport):TpvInt32; overload;
       function AddViewPort(const pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth:TpvFloat):TpvInt32; overload;
       function AddViewPorts(const aViewPorts:array of TVkViewport):TpvInt32; overload;
       function AddScissor(const aScissor:TVkRect2D):TpvInt32; overload;
       function AddScissor(const pX,pY:TpvInt32;const aWidth,aHeight:TpvUInt32):TpvInt32; overload;
       function AddScissors(const aScissors:array of TVkRect2D):TpvInt32; overload;
       procedure SetRasterizationState(const aDepthClampEnable:boolean;
                                       const aRasterizerDiscardEnable:boolean;
                                       const aPolygonMode:TVkPolygonMode;
                                       const aCullMode:TVkCullModeFlags;
                                       const aFrontFace:TVkFrontFace;
                                       const aDepthBiasEnable:boolean;
                                       const aDepthBiasConstantFactor:TpvFloat;
                                       const aDepthBiasClamp:TpvFloat;
                                       const aDepthBiasSlopeFactor:TpvFloat;
                                       const aLineWidth:TpvFloat);
       procedure SetMultisampleState(const aRasterizationSamples:TVkSampleCountFlagBits;
                                     const aSampleShadingEnable:boolean;
                                     const aMinSampleShading:TpvFloat;
                                     const aSampleMask:array of TVkSampleMask;
                                     const aAlphaToCoverageEnable:boolean;
                                     const aAlphaToOneEnable:boolean);
       procedure SetDepthStencilState(const aDepthTestEnable:boolean;
                                      const aDepthWriteEnable:boolean;
                                      const aDepthCompareOp:TVkCompareOp;
                                      const aDepthBoundsTestEnable:boolean;
                                      const aStencilTestEnable:boolean;
                                      const aFront:TVkStencilOpState;
                                      const aBack:TVkStencilOpState;
                                      const aMinDepthBounds:TpvFloat;
                                      const aMaxDepthBounds:TpvFloat);
       procedure SetColorBlendState(const aLogicOpEnable:boolean;
                                    const aLogicOp:TVkLogicOp;
                                    const aBlendConstants:array of TpvFloat);
       function AddColorBlendAttachmentState(const aColorBlendAttachmentState:TVkPipelineColorBlendAttachmentState):TpvInt32; overload;
       function AddColorBlendAttachmentState(const aBlendEnable:boolean;
                                             const aSrcColorBlendFactor:TVkBlendFactor;
                                             const aDstColorBlendFactor:TVkBlendFactor;
                                             const aColorBlendOp:TVkBlendOp;
                                             const aSrcAlphaBlendFactor:TVkBlendFactor;
                                             const aDstAlphaBlendFactor:TVkBlendFactor;
                                             const aAlphaBlendOp:TVkBlendOp;
                                             const aColorWriteMask:TVkColorComponentFlags):TpvInt32; overload;
       function AddColorBlendAttachmentStates(const aColorBlendAttachmentStates:array of TVkPipelineColorBlendAttachmentState):TpvInt32;
       function AddDynamicState(const aDynamicState:TVkDynamicState):TpvInt32;
       function AddDynamicStates(const aDynamicStates:array of TVkDynamicState):TpvInt32;
       procedure Initialize;
       procedure FreeMemory;
      published
       property CountStages:TpvInt32 read GetCountStages;
       property VertexInputState:TpvVulkanPipelineVertexInputState read GetVertexInputState;
       property InputAssemblyState:TpvVulkanPipelineInputAssemblyState read GetInputAssemblyState;
       property TessellationState:TpvVulkanPipelineTessellationState read GetTessellationState;
       property ViewPortState:TpvVulkanPipelineViewPortState read GetViewPortState;
       property RasterizationState:TpvVulkanPipelineRasterizationState read GetRasterizationState;
       property MultisampleState:TpvVulkanPipelineMultisampleState read GetMultisampleState;
       property DepthStencilState:TpvVulkanPipelineDepthStencilState read GetDepthStencilState;
       property ColorBlendState:TpvVulkanPipelineColorBlendState read GetColorBlendState;
       property DynamicState:TpvVulkanPipelineDynamicState read GetDynamicState;
     end;

     TpvVulkanTextureUsageFlag=
      (
       vtufUndefined,
       vtufGeneral,
       vtufTransferSrc,
       vtufTransferDst,
       vtufSampled,
       vtufStorage,
       vtufColorAttachment,
       vtufPresentation
      );

     TpvVulkanTextureUsageFlags=set of TpvVulkanTextureUsageFlag;

     TpvVulkanTextureWrapMode=
      (
       vtwmRepeat,
       vtwmMirroredRepeat,
       vtwmClampToEdge,
       vtwmClampToBorder,
       vtwmMirrorClampToEdge
      );

     TpvVulkanTextureFilterMode=
      (
       vtfmNearest,
       vtfmLinear,
       vtfmBilinear
      );

     TpvVulkanTextureDefaultType=
      (
       vtdtCheckerboard,
       vtdtPyramids,
       vtdtCircles
      );

     TpvVulkanTexture=class(TpvVulkanObject)
      private
       fDevice:TpvVulkanDevice;
       fFormat:TVkFormat;
       fImageLayout:TVkImageLayout;
       fImage:TpvVulkanImage;
       fImageView:TpvVulkanImageView;
       fImageViewType:TVkImageViewType;
       fSampler:TpvVulkanSampler;
       fDescriptorImageInfo:TVkDescriptorImageInfo;
       fMemoryBlock:TpvVulkanDeviceMemoryBlock;
       fWidth:TpvInt32;
       fHeight:TpvInt32;
       fDepth:TpvInt32;
       fCountFaces:TpvInt32;
       fCountArrayLayers:TpvInt32;
       fCountStorageLevels:TpvInt32;
       fCountDataLevels:TpvInt32;
       fCountMipMaps:TpvInt32;
       fTotalCountArrayLayers:TpvInt32;
       fSampleCount:TVkSampleCountFlagBits;
       fUsage:TpvVulkanTextureUsageFlag;
       fUsageFlags:TpvVulkanTextureUsageFlags;
       fWrapModeU:TpvVulkanTextureWrapMode;
       fWrapModeV:TpvVulkanTextureWrapMode;
       fWrapModeW:TpvVulkanTextureWrapMode;
       fFilterMode:TpvVulkanTextureFilterMode;
       fBorderColor:TVkBorderColor;
       fMaxAnisotropy:double;
      public
       constructor Create; reintroduce;
       constructor CreateFromMemory(const aDevice:TpvVulkanDevice;
                                    const aGraphicsQueue:TpvVulkanQueue;
                                    const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                    const aGraphicsFence:TpvVulkanFence;
                                    const aTransferQueue:TpvVulkanQueue;
                                    const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                    const aTransferFence:TpvVulkanFence;
                                    const aFormat:TVkFormat;
                                    const aSampleCount:TVkSampleCountFlagBits;
                                    const aWidth:TpvInt32;
                                    const aHeight:TpvInt32;
                                    const aDepth:TpvInt32;
                                    const aCountArrayLayers:TpvInt32;
                                    const aCountFaces:TpvInt32;
                                    const aCountMipMaps:TpvInt32;
                                    const aUsageFlags:TpvVulkanTextureUsageFlags;
                                    const aData:TpvPointer;
                                    const aDataSize:TVkSizeInt;
                                    const aMipMapSizeStored:boolean;
                                    const aSwapEndianness:boolean;
                                    const aSwapEndiannessTexels:TpvInt32;
                                    const aDDSStructure:boolean=true);
       constructor CreateFromStream(const aDevice:TpvVulkanDevice;
                                    const aGraphicsQueue:TpvVulkanQueue;
                                    const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                    const aGraphicsFence:TpvVulkanFence;
                                    const aTransferQueue:TpvVulkanQueue;
                                    const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                    const aTransferFence:TpvVulkanFence;
                                    const aFormat:TVkFormat;
                                    const aSampleCount:TVkSampleCountFlagBits;
                                    const aWidth:TpvInt32;
                                    const aHeight:TpvInt32;
                                    const aDepth:TpvInt32;
                                    const aCountArrayLayers:TpvInt32;
                                    const aCountFaces:TpvInt32;
                                    const aCountMipMaps:TpvInt32;
                                    const aUsageFlags:TpvVulkanTextureUsageFlags;
                                    const aStream:TStream;
                                    const aMipMapSizeStored:boolean;
                                    const aSwapEndianness:boolean;
                                    const aSwapEndiannessTexels:TpvInt32;
                                    const aDDSStructure:boolean=true);
       constructor CreateFromKTX(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aStream:TStream);
       constructor CreateFromDDS(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aStream:TStream);
       constructor CreateFromHDR(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aStream:TStream;
                                 const aMipMaps:boolean;
                                 const aSRGB:boolean);
       constructor CreateFromTGA(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aStream:TStream;
                                 const aMipMaps:boolean;
                                 const aSRGB:boolean);
       constructor CreateFromPNG(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aStream:TStream;
                                 const aMipMaps:boolean;
                                 const aSRGB:boolean);
       constructor CreateFromJPEG(const aDevice:TpvVulkanDevice;
                                  const aGraphicsQueue:TpvVulkanQueue;
                                  const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                  const aGraphicsFence:TpvVulkanFence;
                                  const aTransferQueue:TpvVulkanQueue;
                                  const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                  const aTransferFence:TpvVulkanFence;
                                  const aStream:TStream;
                                  const aMipMaps:boolean;
                                  const aSRGB:boolean);
       constructor CreateFromBMP(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aStream:TStream;
                                 const aMipMaps:boolean;
                                 const aSRGB:boolean);
       constructor CreateFromImage(const aDevice:TpvVulkanDevice;
                                   const aGraphicsQueue:TpvVulkanQueue;
                                   const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                   const aGraphicsFence:TpvVulkanFence;
                                   const aTransferQueue:TpvVulkanQueue;
                                   const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                   const aTransferFence:TpvVulkanFence;
                                   const aStream:TStream;
                                   const aMipMaps:boolean;
                                   const aSRGB:boolean);
       constructor CreateDefault(const aDevice:TpvVulkanDevice;
                                 const aGraphicsQueue:TpvVulkanQueue;
                                 const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                 const aGraphicsFence:TpvVulkanFence;
                                 const aTransferQueue:TpvVulkanQueue;
                                 const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                 const aTransferFence:TpvVulkanFence;
                                 const aDefaultType:TpvVulkanTextureDefaultType;
                                 const aWidth:TpvInt32;
                                 const aHeight:TpvInt32;
                                 const aDepth:TpvInt32;
                                 const aCountArrayLayers:TpvInt32;
                                 const aCountFaces:TpvInt32;
                                 const aMipmaps:boolean;
                                 const aBorder:boolean;
                                 const aSRGB:boolean);
       destructor Destroy; override;
       procedure Upload(const aGraphicsQueue:TpvVulkanQueue;
                        const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                        const aGraphicsFence:TpvVulkanFence;
                        const aTransferQueue:TpvVulkanQueue;
                        const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                        const aTransferFence:TpvVulkanFence;
                        const aData:TpvPointer;
                        const aDataSize:TVkSizeInt;
                        const aMipMapSizeStored:boolean=false;
                        const aSwapEndianness:boolean=false;
                        const aSwapEndiannessTexels:TpvInt32=0;
                        const aDDSStructure:boolean=true;
                        const aStagingBuffer:TpvVulkanBuffer=nil);
       procedure UpdateSampler;
       property DescriptorImageInfo:TVkDescriptorImageInfo read fDescriptorImageInfo;
      published
       property Device:TpvVulkanDevice read fDevice;
       property Format:TVkFormat read fFormat;
       property ImageLayout:TVkImageLayout read fImageLayout;
       property Image:TpvVulkanImage read fImage;
       property ImageView:TpvVulkanImageView read fImageView;
       property ImageViewType:TVkImageViewType read fImageViewType;
       property Sampler:TpvVulkanSampler read fSampler;
       property MemoryBlock:TpvVulkanDeviceMemoryBlock read fMemoryBlock;
       property Width:TpvInt32 read fWidth;
       property Height:TpvInt32 read fHeight;
       property Depth:TpvInt32 read fDepth;
       property CountFaces:TpvInt32 read fCountFaces;
       property CountArrayLayers:TpvInt32 read fCountArrayLayers;
       property CountStorageLevels:TpvInt32 read fCountStorageLevels;
       property CountDataLevels:TpvInt32 read fCountDataLevels;
       property CountMipMaps:TpvInt32 read fCountMipMaps;
       property TotalCountArrayLayers:TpvInt32 read fTotalCountArrayLayers;
       property SampleCount:TVkSampleCountFlagBits read fSampleCount;
       property Usage:TpvVulkanTextureUsageFlag read fUsage;
       property UsageFlags:TpvVulkanTextureUsageFlags read fUsageFlags;
       property WrapModeU:TpvVulkanTextureWrapMode read fWrapModeU write fWrapModeU;
       property WrapModeV:TpvVulkanTextureWrapMode read fWrapModeV write fWrapModeV;
       property WrapModeW:TpvVulkanTextureWrapMode read fWrapModeW write fWrapModeW;
       property FilterMode:TpvVulkanTextureFilterMode read fFilterMode write fFilterMode;
       property BorderColor:TVkBorderColor read fBorderColor write fBorderColor;
       property MaxAnisotropy:double read fMaxAnisotropy write fMaxAnisotropy;
     end;

const VulkanImageViewTypeToImageTiling:array[TVkImageViewType] of TVkImageTiling=
       (
        VK_IMAGE_TILING_LINEAR,  // VK_IMAGE_VIEW_TYPE_1D
        VK_IMAGE_TILING_OPTIMAL, // VK_IMAGE_VIEW_TYPE_2D
        VK_IMAGE_TILING_OPTIMAL, // VK_IMAGE_VIEW_TYPE_3D
        VK_IMAGE_TILING_OPTIMAL, // VK_IMAGE_VIEW_TYPE_CUBE
        VK_IMAGE_TILING_LINEAR,  // VK_IMAGE_VIEW_TYPE_1D_ARRAY
        VK_IMAGE_TILING_OPTIMAL, // VK_IMAGE_VIEW_TYPE_2D_ARRAY
        VK_IMAGE_TILING_LINEAR   // VK_IMAGE_VIEW_TYPE_CUBE_ARRAY
       );

function VulkanGetFormatFromOpenGLFormat(const aFormat,aType:TpvUInt32):TVkFormat;
function VulkanGetFormatFromOpenGLType(const aType,aNumComponents:TpvUInt32;const aNormalized:boolean):TVkFormat;
function VulkanGetFormatFromOpenGLInternalFormat(const aInternalFormat:TpvUInt32):TVkFormat;

function VulkanGetFormatSize(const aFormat:TVkFormat):TpvVulkanFormatSize;

function VulkanRoundUpToPowerOfTwo(Value:TVkSize):TVkSize;

function VulkanErrorToString(const ErrorCode:TVkResult):TpvVulkanCharString;

function StringListToVulkanCharStringArray(const StringList:TStringList):TpvVulkanCharStringArray;

procedure VulkanSetImageLayout(const aImage:TVkImage;
                               const aAspectMask:TVkImageAspectFlags;
                               const aOldImageLayout:TVkImageLayout;
                               const aNewImageLayout:TVkImageLayout;
                               const aRange:PVkImageSubresourceRange;
                               const aCommandBuffer:TpvVulkanCommandBuffer;
                               const aQueue:TpvVulkanQueue=nil;
                               const aFence:TpvVulkanFence=nil;
                               const aBeginAndExecuteCommandBuffer:boolean=false;
                               const aSrcQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED);
                               const aDstQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED));

procedure VulkanDisableFloatingPointExceptions;

implementation

uses PasVulkan.Utils;

const BooleanToVkBool:array[boolean] of TVkBool32=(VK_FALSE,VK_TRUE);

      MipMapLevels:array[boolean] of TpvInt32=(1,-1);

      CELL_EMPTY=-1;
      CELL_DELETED=-2;
      ENT_EMPTY=-1;
      ENT_DELETED=-2;

      GL_INVALID_VALUE=$0501;
      GL_RED=$1903; // same as GL_RED_EXT
      GL_GREEN=$1904; // deprecated
      GL_BLUE=$1905; // deprecated
      GL_ALPHA=$1906; // deprecated
      GL_LUMINANCE=$1909; // deprecated
      GL_SLUMINANCE=$8c46; // deprecated, same as GL_SLUMINANCE_EXT
      GL_LUMINANCE_ALPHA=$190a; // deprecated
      GL_SLUMINANCE_ALPHA=$8c44; // deprecated, same as GL_SLUMINANCE_ALPHA_EXT
      GL_INTENSITY=$8049; // deprecated, same as GL_INTENSITY_EXT
      GL_RG=$8227; // same as GL_RG_EXT
      GL_RGB=$1907;
      GL_BGR=$80e0; // same as GL_BGR_EXT
      GL_RGBA=$1908;
      GL_BGRA=$80e1; // same as GL_BGRA_EXT
      GL_RED_INTEGER=$8d94; // same as GL_RED_INTEGER_EXT
      GL_GREEN_INTEGER=$8d95; // deprecated, same as GL_GREEN_INTEGER_EXT
      GL_BLUE_INTEGER=$8d96; // deprecated, same as GL_BLUE_INTEGER_EXT
      GL_ALPHA_INTEGER=$8d97; // deprecated, same as GL_ALPHA_INTEGER_EXT
      GL_LUMINANCE_INTEGER=$8d9c; // deprecated, same as GL_LUMINANCE_INTEGER_EXT
      GL_LUMINANCE_ALPHA_INTEGER=$8d9d; // deprecated, same as GL_LUMINANCE_ALPHA_INTEGER_EXT
      GL_RG_INTEGER=$8228; // same as GL_RG_INTEGER_EXT
      GL_RGB_INTEGER=$8d98; // same as GL_RGB_INTEGER_EXT
      GL_BGR_INTEGER=$8d9a; // same as GL_BGR_INTEGER_EXT
      GL_RGBA_INTEGER=$8d99; // same as GL_RGBA_INTEGER_EXT
      GL_BGRA_INTEGER=$8d9b; // same as GL_BGRA_INTEGER_EXT
      GL_COLOR_INDEX=$1900; // deprecated
      GL_STENCIL_INDEX=$1901;
      GL_DEPTH_COMPONENT=$1902;
      GL_DEPTH_STENCIL=$84f9; // same as GL_DEPTH_STENCIL_NV and GL_DEPTH_STENCIL_EXT and GL_DEPTH_STENCIL_OES
      GL_BYTE=$1400;
      GL_UNSIGNED_BYTE=$1401;
      GL_SHORT=$1402;
      GL_UNSIGNED_SHORT=$1403;
      GL_INT=$1404;
      GL_UNSIGNED_INT=$1405;
      GL_INT64=$140e; // same as GL_INT64_NV and GL_INT64_ARB
      GL_UNSIGNED_INT64=$140f; // same as GL_UNSIGNED_INT64_NV and GL_UNSIGNED_INT64_ARB
      GL_HALF_FLOAT=$140b; // same as GL_HALF_FLOAT_NV and GL_HALF_FLOAT_ARB
      GL_HALF_FLOAT_OES=$8d61; // Note that this different from GL_HALF_FLOAT.
      GL_FLOAT=$1406;
      GL_DOUBLE=$140a; // same as GL_DOUBLE_EXT
      GL_UNSIGNED_BYTE_3_3_2=$8032; // same as GL_UNSIGNED_BYTE_3_3_2_EXT
      GL_UNSIGNED_BYTE_2_3_3_REV=$8362; // same as GL_UNSIGNED_BYTE_2_3_3_REV_EXT
      GL_UNSIGNED_SHORT_5_6_5=$8363; // same as GL_UNSIGNED_SHORT_5_6_5_EXT
      GL_UNSIGNED_SHORT_5_6_5_REV=$8364; // same as GL_UNSIGNED_SHORT_5_6_5_REV_EXT
      GL_UNSIGNED_SHORT_4_4_4_4=$8033; // same as GL_UNSIGNED_SHORT_4_4_4_4_EXT
      GL_UNSIGNED_SHORT_4_4_4_4_REV=$8365; // same as GL_UNSIGNED_SHORT_4_4_4_4_REV_IMG and GL_UNSIGNED_SHORT_4_4_4_4_REV_EXT
      GL_UNSIGNED_SHORT_5_5_5_1=$8034; // same as GL_UNSIGNED_SHORT_5_5_5_1_EXT
      GL_UNSIGNED_SHORT_1_5_5_5_REV=$8366; // same as GL_UNSIGNED_SHORT_1_5_5_5_REV_EXT
      GL_UNSIGNED_INT_8_8_8_8=$8035; // same as GL_UNSIGNED_INT_8_8_8_8_EXT
      GL_UNSIGNED_INT_8_8_8_8_REV=$8367; // same as GL_UNSIGNED_INT_8_8_8_8_REV_EXT
      GL_UNSIGNED_INT_10_10_10_2=$8036; // same as GL_UNSIGNED_INT_10_10_10_2_EXT
      GL_UNSIGNED_INT_2_10_10_10_REV=$8368; // same as GL_UNSIGNED_INT_2_10_10_10_REV_EXT
      GL_UNSIGNED_INT_10F_11F_11F_REV=$8c3b; // same as GL_UNSIGNED_INT_10F_11F_11F_REV_EXT
      GL_UNSIGNED_INT_5_9_9_9_REV=$8c3e; // same as GL_UNSIGNED_INT_5_9_9_9_REV_EXT
      GL_UNSIGNED_INT_24_8=$84fa; // same as GL_UNSIGNED_INT_24_8_NV and GL_UNSIGNED_INT_24_8_EXT and GL_UNSIGNED_INT_24_8_OES
      GL_FLOAT_32_UNSIGNED_INT_24_8_REV=$8dad; // same as GL_FLOAT_32_UNSIGNED_INT_24_8_REV_NV and GL_FLOAT_32_UNSIGNED_INT_24_8_REV_ARB
      GL_R8=$8229; // same as GL_R8_EXT
      GL_RG8=$822b; // same as GL_RG8_EXT
      GL_RGB8=$8051; // same as GL_RGB8_EXT and GL_RGB8_OES
      GL_RGBA8=$8058; // same as GL_RGBA8_EXT and GL_RGBA8_OES
      GL_R8_SNORM=$8f94;
      GL_RG8_SNORM=$8f95;
      GL_RGB8_SNORM=$8f96;
      GL_RGBA8_SNORM=$8f97;
      GL_R8UI=$8232;
      GL_RG8UI=$8238;
      GL_RGB8UI=$8d7d; // same as GL_RGB8UI_EXT
      GL_RGBA8UI=$8d7c; // same as GL_RGBA8UI_EXT
      GL_R8I=$8231;
      GL_RG8I=$8237;
      GL_RGB8I=$8d8f; // same as GL_RGB8I_EXT
      GL_RGBA8I=$8d8e; // same as GL_RGBA8I_EXT
      GL_SR8=$8fbd; // same as GL_SR8_EXT
      GL_SRG8=$8fbe; // same as GL_SRG8_EXT
      GL_SRGB8=$8c41; // same as GL_SRGB8_EXT
      GL_SRGB8_ALPHA8=$8c43; // same as GL_SRGB8_ALPHA8_EXT
      GL_R16=$822a; // same as GL_R16_EXT
      GL_RG16=$822c; // same as GL_RG16_EXT
      GL_RGB16=$8054; // same as GL_RGB16_EXT
      GL_RGBA16=$805b; // same as GL_RGBA16_EXT
      GL_R16_SNORM=$8f98; // same as GL_R16_SNORM_EXT
      GL_RG16_SNORM=$8f99; // same as GL_RG16_SNORM_EXT
      GL_RGB16_SNORM=$8f9a; // same as GL_RGB16_SNORM_EXT
      GL_RGBA16_SNORM=$8f9b; // same as GL_RGBA16_SNORM_EXT
      GL_R16UI=$8234;
      GL_RG16UI=$823a;
      GL_RGB16UI=$8d77; // same as GL_RGB16UI_EXT
      GL_RGBA16UI=$8d76; // same as GL_RGBA16UI_EXT
      GL_R16I=$8233;
      GL_RG16I=$8239;
      GL_RGB16I=$8d89; // same as GL_RGB16I_EXT
      GL_RGBA16I=$8d88; // same as GL_RGBA16I_EXT
      GL_R16F=$822d; // same as GL_R16F_EXT
      GL_RG16F=$822f; // same as GL_RG16F_EXT
      GL_RGB16F=$881b; // same as GL_RGB16F_EXT and GL_RGB16F_ARB
      GL_RGBA16F=$881a; // sama as GL_RGBA16F_EXT and GL_RGBA16F_ARB
      GL_R32UI=$8236;
      GL_RG32UI=$823c;
      GL_RGB32UI=$8d71; // same as GL_RGB32UI_EXT
      GL_RGBA32UI=$8d70; // same as GL_RGBA32UI_EXT
      GL_R32I=$8235;
      GL_RG32I=$823b;
      GL_RGB32I=$8d83; // same as GL_RGB32I_EXT
      GL_RGBA32I=$8d82; // same as GL_RGBA32I_EXT
      GL_R32F=$822e; // same as GL_R32F_EXT
      GL_RG32F=$8230; // same as GL_RG32F_EXT
      GL_RGB32F=$8815; // same as GL_RGB32F_EXT and GL_RGB32F_ARB
      GL_RGBA32F=$8814; // same as GL_RGBA32F_EXT and GL_RGBA32F_ARB
      GL_R3_G3_B2=$2a10;
      GL_RGB4=$804f; // same as GL_RGB4_EXT
      GL_RGB5=$8050; // same as GL_RGB5_EXT
      GL_RGB565=$8d62; // same as GL_RGB565_EXT and GL_RGB565_OES
      GL_RGB10=$8052; // same as GL_RGB10_EXT
      GL_RGB12=$8053; // same as GL_RGB12_EXT
      GL_RGBA2=$8055; // same as GL_RGBA2_EXT
      GL_RGBA4=$8056; // same as GL_RGBA4_EXT and GL_RGBA4_OES
      GL_RGBA12=$805a; // same as GL_RGBA12_EXT
      GL_RGB5_A1=$8057; // same as GL_RGB5_A1_EXT and GL_RGB5_A1_OES
      GL_RGB10_A2=$8059; // same as GL_RGB10_A2_EXT
      GL_RGB10_A2UI=$906f;
      GL_R11F_G11F_B10F=$8c3a; // same as GL_R11F_G11F_B10F_APPLE and GL_R11F_G11F_B10F_EXT
      GL_RGB9_E5=$8c3d; // same as GL_RGB9_E5_APPLE and GL_RGB9_E5_EXT
      GL_ALPHA4=$803b; // deprecated, same as GL_ALPHA4_EXT
      GL_ALPHA8=$803c; // deprecated, same as GL_ALPHA8_EXT
      GL_ALPHA8_SNORM=$9014; // deprecated
      GL_ALPHA8UI_EXT=$8d7e; // deprecated
      GL_ALPHA8I_EXT=$8d90; // deprecated
      GL_ALPHA12=$803d; // deprecated, same as GL_ALPHA12_EXT
      GL_ALPHA16=$803e; // deprecated, same as GL_ALPHA16_EXT
      GL_ALPHA16_SNORM=$9018; // deprecated
      GL_ALPHA16UI_EXT=$8d78; // deprecated
      GL_ALPHA16I_EXT=$8d8a; // deprecated
      GL_ALPHA16F_ARB=$881c; // deprecated, same as GL_ALPHA_FLOAT16_APPLE and GL_ALPHA_FLOAT16_ATI
      GL_ALPHA32UI_EXT=$8d72; // deprecated
      GL_ALPHA32I_EXT=$8d84; // deprecated
      GL_ALPHA32F_ARB=$8816; // deprecated, same as GL_ALPHA_FLOAT32_APPLE and GL_ALPHA_FLOAT32_ATI
      GL_LUMINANCE4=$803f; // deprecated, same as GL_LUMINANCE4_EXT
      GL_LUMINANCE8=$8040; // deprecated, same as GL_LUMINANCE8_EXT
      GL_LUMINANCE8_SNORM=$9015; // deprecated
      GL_SLUMINANCE8=$8c47; // deprecated, same as GL_SLUMINANCE8_EXT
      GL_LUMINANCE8UI_EXT=$8d80; // deprecated
      GL_LUMINANCE8I_EXT=$8d92; // deprecated
      GL_LUMINANCE12=$8041; // deprecated, same as GL_LUMINANCE12_EXT
      GL_LUMINANCE16=$8042; // deprecated, same as GL_LUMINANCE16_EXT
      GL_LUMINANCE16_SNORM=$9019; // deprecated
      GL_LUMINANCE16UI_EXT=$8d7a; // deprecated
      GL_LUMINANCE16I_EXT=$8d8c; // deprecated
      GL_LUMINANCE16F_ARB=$881e; // deprecated, same as GL_LUMINANCE_FLOAT16_APPLE and GL_LUMINANCE_FLOAT16_ATI
      GL_LUMINANCE32UI_EXT=$8d74; // deprecated
      GL_LUMINANCE32I_EXT=$8d86; // deprecated
      GL_LUMINANCE32F_ARB=$8818; // deprecated, same as GL_LUMINANCE_FLOAT32_APPLE and GL_LUMINANCE_FLOAT32_ATI
      GL_LUMINANCE4_ALPHA4=$8043; // deprecated, same as GL_LUMINANCE4_ALPHA4_EXT
      GL_LUMINANCE6_ALPHA2=$8044; // deprecated, same as GL_LUMINANCE6_ALPHA2_EXT
      GL_LUMINANCE8_ALPHA8=$8045; // deprecated, same as GL_LUMINANCE8_ALPHA8_EXT
      GL_LUMINANCE8_ALPHA8_SNORM=$9016; // deprecated
      GL_SLUMINANCE8_ALPHA8=$8c45; // deprecated, same as GL_SLUMINANCE8_ALPHA8_EXT
      GL_LUMINANCE_ALPHA8UI_EXT=$8d81; // deprecated
      GL_LUMINANCE_ALPHA8I_EXT=$8d93; // deprecated
      GL_LUMINANCE12_ALPHA4=$8046; // deprecated, same as GL_LUMINANCE12_ALPHA4_EXT
      GL_LUMINANCE12_ALPHA12=$8047; // deprecated, same as GL_LUMINANCE12_ALPHA12_EXT
      GL_LUMINANCE16_ALPHA16=$8048; // deprecated, same as GL_LUMINANCE16_ALPHA16_EXT
      GL_LUMINANCE16_ALPHA16_SNORM=$901a; // deprecated
      GL_LUMINANCE_ALPHA16UI_EXT=$8d7b; // deprecated
      GL_LUMINANCE_ALPHA16I_EXT=$8d8d; // deprecated
      GL_LUMINANCE_ALPHA16F_ARB=$881f; // deprecated, same as GL_LUMINANCE_ALPHA_FLOAT16_APPLE and GL_LUMINANCE_ALPHA_FLOAT16_ATI
      GL_LUMINANCE_ALPHA32UI_EXT=$8d75; // deprecated
      GL_LUMINANCE_ALPHA32I_EXT=$8d87; // deprecated
      GL_LUMINANCE_ALPHA32F_ARB=$8819; // deprecated, same as GL_LUMINANCE_ALPHA_FLOAT32_APPLE and GL_LUMINANCE_ALPHA_FLOAT32_ATI
      GL_INTENSITY4=$804a; // deprecated, same as GL_INTENSITY4_EXT
      GL_INTENSITY8=$804b; // deprecated, same as GL_INTENSITY8_EXT
      GL_INTENSITY8_SNORM=$9017; // deprecated
      GL_INTENSITY8UI_EXT=$8d7f; // deprecated
      GL_INTENSITY8I_EXT=$8d91; // deprecated
      GL_INTENSITY12=$804c; // deprecated, same as GL_INTENSITY12_EXT
      GL_INTENSITY16=$804d; // deprecated, same as GL_INTENSITY16_EXT
      GL_INTENSITY16_SNORM=$901b; // deprecated
      GL_INTENSITY16UI_EXT=$8d79; // deprecated
      GL_INTENSITY16I_EXT=$8d8b; // deprecated
      GL_INTENSITY16F_ARB=$881d; // deprecated, same as GL_INTENSITY_FLOAT16_APPLE and GL_INTENSITY_FLOAT16_ATI
      GL_INTENSITY32UI_EXT=$8d73; // deprecated
      GL_INTENSITY32I_EXT=$8d85; // deprecated
      GL_INTENSITY32F_ARB=$8817; // deprecated, same as GL_INTENSITY_FLOAT32_APPLE and GL_INTENSITY_FLOAT32_ATI
      GL_COMPRESSED_RED=$8225;
      GL_COMPRESSED_ALPHA=$84e9; // deprecated, same as GL_COMPRESSED_ALPHA_ARB
      GL_COMPRESSED_LUMINANCE=$84ea; // deprecated, same as GL_COMPRESSED_LUMINANCE_ARB
      GL_COMPRESSED_SLUMINANCE=$8c4a; // deprecated, same as GL_COMPRESSED_SLUMINANCE_EXT
      GL_COMPRESSED_LUMINANCE_ALPHA=$84eb; // deprecated, same as GL_COMPRESSED_LUMINANCE_ALPHA_ARB
      GL_COMPRESSED_SLUMINANCE_ALPHA=$8c4b; // deprecated, same as GL_COMPRESSED_SLUMINANCE_ALPHA_EXT
      GL_COMPRESSED_INTENSITY=$84ec; // deprecated, same as GL_COMPRESSED_INTENSITY_ARB
      GL_COMPRESSED_RG=$8226;
      GL_COMPRESSED_RGB=$84ed; // same as GL_COMPRESSED_RGB_ARB
      GL_COMPRESSED_RGBA=$84ee; // same as GL_COMPRESSED_RGBA_ARB
      GL_COMPRESSED_SRGB=$8c48; // same as GL_COMPRESSED_SRGB_EXT
      GL_COMPRESSED_SRGB_ALPHA=$8c49; // same as GL_COMPRESSED_SRGB_ALPHA_EXT
      GL_COMPRESSED_RGB_FXT1_3DFX=$86b0; // deprecated
      GL_COMPRESSED_RGBA_FXT1_3DFX=$86b1; // deprecated
      GL_COMPRESSED_RGB_S3TC_DXT1_EXT=$83f0;
      GL_COMPRESSED_RGBA_S3TC_DXT1_EXT=$83f1;
      GL_COMPRESSED_RGBA_S3TC_DXT3_EXT=$83f2;
      GL_COMPRESSED_RGBA_S3TC_DXT5_EXT=$83f3;
      GL_COMPRESSED_SRGB_S3TC_DXT1_EXT=$8c4c;
      GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT=$8c4d;
      GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT=$8c4e;
      GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT=$8c4f;
      GL_COMPRESSED_LUMINANCE_LATC1_EXT=$8c70;
      GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT=$8c72;
      GL_COMPRESSED_SIGNED_LUMINANCE_LATC1_EXT=$8c71;
      GL_COMPRESSED_SIGNED_LUMINANCE_ALPHA_LATC2_EXT=$8c73;
      GL_COMPRESSED_RED_RGTC1=$8dbb; // same as GL_COMPRESSED_RED_RGTC1_EXT
      GL_COMPRESSED_RG_RGTC2=$8dbd; // same as GL_COMPRESSED_RG_RGTC2_EXT
      GL_COMPRESSED_SIGNED_RED_RGTC1=$8dbc; // same as GL_COMPRESSED_SIGNED_RED_RGTC1_EXT
      GL_COMPRESSED_SIGNED_RG_RGTC2=$8dbe; // same as GL_COMPRESSED_SIGNED_RG_RGTC2_EXT
      GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT=$8e8e; // same as GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB
      GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT=$8e8f; // same as GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB
      GL_COMPRESSED_RGBA_BPTC_UNORM=$8e8c; // same as GL_COMPRESSED_RGBA_BPTC_UNORM_ARB
      GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM=$8e8d; // same as GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB
      GL_ETC1_RGB8_OES=$8d64;
      GL_COMPRESSED_RGB8_ETC2=$9274;
      GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2=$9276;
      GL_COMPRESSED_RGBA8_ETC2_EAC=$9278;
      GL_COMPRESSED_SRGB8_ETC2=$9275;
      GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2=$9277;
      GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC=$9279;
      GL_COMPRESSED_R11_EAC=$9270;
      GL_COMPRESSED_RG11_EAC=$9272;
      GL_COMPRESSED_SIGNED_R11_EAC=$9271;
      GL_COMPRESSED_SIGNED_RG11_EAC=$9273;
      GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG=$8c01;
      GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG=$8c00;
      GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG=$8c03;
      GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG=$8c02;
      GL_COMPRESSED_RGBA_PVRTC_2BPPV2_IMG=$9137;
      GL_COMPRESSED_RGBA_PVRTC_4BPPV2_IMG=$9138;
      GL_COMPRESSED_SRGB_PVRTC_2BPPV1_EXT=$8a54;
      GL_COMPRESSED_SRGB_PVRTC_4BPPV1_EXT=$8a55;
      GL_COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV1_EXT=$8a56;
      GL_COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV1_EXT=$8a57;
      GL_COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV2_IMG=$93f0;
      GL_COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV2_IMG=$93f1;
      GL_COMPRESSED_RGBA_ASTC_4x4_KHR=$93b0;
      GL_COMPRESSED_RGBA_ASTC_5x4_KHR=$93b1;
      GL_COMPRESSED_RGBA_ASTC_5x5_KHR=$93b2;
      GL_COMPRESSED_RGBA_ASTC_6x5_KHR=$93b3;
      GL_COMPRESSED_RGBA_ASTC_6x6_KHR=$93b4;
      GL_COMPRESSED_RGBA_ASTC_8x5_KHR=$93b5;
      GL_COMPRESSED_RGBA_ASTC_8x6_KHR=$93b6;
      GL_COMPRESSED_RGBA_ASTC_8x8_KHR=$93b7;
      GL_COMPRESSED_RGBA_ASTC_10x5_KHR=$93b8;
      GL_COMPRESSED_RGBA_ASTC_10x6_KHR=$93b9;
      GL_COMPRESSED_RGBA_ASTC_10x8_KHR=$93ba;
      GL_COMPRESSED_RGBA_ASTC_10x10_KHR=$93bb;
      GL_COMPRESSED_RGBA_ASTC_12x10_KHR=$93bc;
      GL_COMPRESSED_RGBA_ASTC_12x12_KHR=$93bd;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR=$93d0;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR=$93d1;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR=$93d2;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR=$93d3;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR=$93d4;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR=$93d5;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR=$93d6;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR=$93d7;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR=$93d8;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR=$93d9;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR=$93da;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR=$93db;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR=$93dc;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR=$93dd;
      GL_COMPRESSED_RGBA_ASTC_3x3x3_OES=$93c0;
      GL_COMPRESSED_RGBA_ASTC_4x3x3_OES=$93c1;
      GL_COMPRESSED_RGBA_ASTC_4x4x3_OES=$93c2;
      GL_COMPRESSED_RGBA_ASTC_4x4x4_OES=$93c3;
      GL_COMPRESSED_RGBA_ASTC_5x4x4_OES=$93c4;
      GL_COMPRESSED_RGBA_ASTC_5x5x4_OES=$93c5;
      GL_COMPRESSED_RGBA_ASTC_5x5x5_OES=$93c6;
      GL_COMPRESSED_RGBA_ASTC_6x5x5_OES=$93c7;
      GL_COMPRESSED_RGBA_ASTC_6x6x5_OES=$93c8;
      GL_COMPRESSED_RGBA_ASTC_6x6x6_OES=$93c9;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_3x3x3_OES=$93e0;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x3x3_OES=$93e1;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4x3_OES=$93e2;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4x4_OES=$93e3;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4x4_OES=$93e4;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5x4_OES=$93e5;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5x5_OES=$93e6;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5x5_OES=$93e7;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6x5_OES=$93e8;
      GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6x6_OES=$93e9;
      GL_ATC_RGB_AMD=$8c92;
      GL_ATC_RGBA_EXPLICIT_ALPHA_AMD=$8c93;
      GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD=$87ee;
      GL_PALETTE4_RGB8_OES=$8b90;
      GL_PALETTE4_RGBA8_OES=$8b91;
      GL_PALETTE4_R5_G6_B5_OES=$8b92;
      GL_PALETTE4_RGBA4_OES=$8b93;
      GL_PALETTE4_RGB5_A1_OES=$8b94;
      GL_PALETTE8_RGB8_OES=$8b95;
      GL_PALETTE8_RGBA8_OES=$8b96;
      GL_PALETTE8_R5_G6_B5_OES=$8b97;
      GL_PALETTE8_RGBA4_OES=$8b98;
      GL_PALETTE8_RGB5_A1_OES=$8b99;
      GL_COLOR_INDEX1_EXT=$80e2; // deprecated
      GL_COLOR_INDEX2_EXT=$80e3; // deprecated
      GL_COLOR_INDEX4_EXT=$80e4; // deprecated
      GL_COLOR_INDEX8_EXT=$80e5; // deprecated
      GL_COLOR_INDEX12_EXT=$80e6; // deprecated
      GL_COLOR_INDEX16_EXT=$80e7; // deprecated
      GL_DEPTH_COMPONENT16=$81a5; // same as GL_DEPTH_COMPONENT16_SGIX and GL_DEPTH_COMPONENT16_ARB
      GL_DEPTH_COMPONENT24=$81a6; // same as GL_DEPTH_COMPONENT24_SGIX and GL_DEPTH_COMPONENT24_ARB
      GL_DEPTH_COMPONENT32=$81a7; // same as GL_DEPTH_COMPONENT32_SGIX and GL_DEPTH_COMPONENT32_ARB and GL_DEPTH_COMPONENT32_OES
      GL_DEPTH_COMPONENT32F=$8cac; // same as GL_DEPTH_COMPONENT32F_ARB
      GL_DEPTH_COMPONENT32F_NV=$8dab; // Note that this different from GL_DEPTH_COMPONENT32F.
      GL_STENCIL_INDEX1=$8d46; // same as GL_STENCIL_INDEX1_EXT
      GL_STENCIL_INDEX4=$8d47; // same as GL_STENCIL_INDEX4_EXT
      GL_STENCIL_INDEX8=$8d48; // same as GL_STENCIL_INDEX8_EXT
      GL_STENCIL_INDEX16=$8d49; // same as GL_STENCIL_INDEX16_EXT
      GL_DEPTH24_STENCIL8=$88f0; // same as GL_DEPTH24_STENCIL8_EXT and GL_DEPTH24_STENCIL8_OES
      GL_DEPTH32F_STENCIL8=$8cad; // same as GL_DEPTH32F_STENCIL8_ARB
      GL_DEPTH32F_STENCIL8_NV=$8dac; // Note that this different from GL_DEPTH32F_STENCIL8.

type PUInt32Array=^TUInt32Array;
     TUInt32Array=array[0..65535] of TpvUInt32;

function VulkanGetFormatFromOpenGLFormat(const aFormat,aType:TpvUInt32):TVkFormat;
begin
 case aType of
  GL_UNSIGNED_BYTE:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R8_UNORM;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R8G8_UNORM;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R8G8B8_UNORM;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_B8G8R8_UNORM;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R8G8B8A8_UNORM;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_B8G8R8A8_UNORM;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R8_UINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R8G8_UINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R8G8B8_UINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_B8G8R8_UINT;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R8G8B8A8_UINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_B8G8R8A8_UINT;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_S8_UINT;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_BYTE:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R8_SNORM;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R8G8_SNORM;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R8G8B8_SNORM;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_B8G8R8_SNORM;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R8G8B8A8_SNORM;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_B8G8R8A8_SNORM;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R8_SINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R8G8_SINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R8G8B8_SINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_B8G8R8_SINT;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R8G8B8A8_SINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_B8G8R8A8_SINT;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R16_UNORM;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R16G16_UNORM;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R16G16B16_UNORM;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R16G16B16A16_UNORM;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R16_UINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R16G16_UINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R16G16B16_UINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R16G16B16A16_UINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_D16_UNORM;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_D16_UNORM_S8_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_SHORT:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R16_SNORM;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R16G16_SNORM;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R16G16B16_SNORM;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R16G16B16A16_SNORM;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R16_SINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R16G16_SINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R16G16B16_SINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R16G16B16A16_SINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_HALF_FLOAT,GL_HALF_FLOAT_OES:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R16_SFLOAT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R16G16_SFLOAT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R16G16B16_SFLOAT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R16G16B16A16_SFLOAT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R32_UINT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R32G32_UINT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R32G32B32_UINT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R32G32B32A32_UINT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R32_UINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R32G32_UINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R32G32B32_UINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R32G32B32A32_UINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_X8_D24_UNORM_PACK32;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_D24_UNORM_S8_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_INT:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R32_SINT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R32G32_SINT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R32G32B32_SINT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R32G32B32A32_SINT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R32_SINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R32G32_SINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R32G32B32_SINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R32G32B32A32_SINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_FLOAT:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R32_SFLOAT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R32G32_SFLOAT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R32G32B32_SFLOAT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R32G32B32A32_SFLOAT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_D32_SFLOAT;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_D32_SFLOAT_S8_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT64:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R64_UINT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R64G64_UINT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R64G64B64_UINT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R64G64B64A64_UINT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_INT64:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R64_SINT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R64G64_SINT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R64G64B64_SINT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R64G64B64A64_SINT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R64_SINT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R64G64_SINT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R64G64B64_SINT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R64G64B64A64_SINT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_DOUBLE:begin
   case aFormat of
    GL_RED:begin
     result:=VK_FORMAT_R64_SFLOAT;
    end;
    GL_RG:begin
     result:=VK_FORMAT_R64G64_SFLOAT;
    end;
    GL_RGB:begin
     result:=VK_FORMAT_R64G64B64_SFLOAT;
    end;
    GL_BGR:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA:begin
     result:=VK_FORMAT_R64G64B64A64_SFLOAT;
    end;
    GL_BGRA:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RED_INTEGER:begin
     result:=VK_FORMAT_R64_SFLOAT;
    end;
    GL_RG_INTEGER:begin
     result:=VK_FORMAT_R64G64_SFLOAT;
    end;
    GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R64G64B64_SFLOAT;
    end;
    GL_BGR_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_RGBA_INTEGER:begin
     result:=VK_FORMAT_R64G64B64A64_SFLOAT;
    end;
    GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_STENCIL_INDEX:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_COMPONENT:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_UNDEFINED;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_BYTE_3_3_2:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_UNSIGNED_BYTE_2_3_3_REV:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_UNSIGNED_SHORT_5_6_5:begin
   case aFormat of
    GL_RGB,GL_RGB_INTEGER:begin
     result:=VK_FORMAT_R5G6B5_UNORM_PACK16;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT_5_6_5_REV:begin
   case aFormat of
    GL_BGR,GL_BGR_INTEGER:begin
     result:=VK_FORMAT_B5G6R5_UNORM_PACK16;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT_4_4_4_4:begin
   case aFormat of
    GL_RGB,GL_BGRA,GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_R4G4B4A4_UNORM_PACK16;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT_4_4_4_4_REV:begin
   case aFormat of
    GL_RGB,GL_BGRA,GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_B4G4R4A4_UNORM_PACK16;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT_5_5_5_1:begin
   case aFormat of
    GL_RGB,GL_BGRA,GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_R5G5B5A1_UNORM_PACK16;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT_1_5_5_5_REV:begin
   case aFormat of
    GL_RGB,GL_BGRA,GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_A1R5G5B5_UNORM_PACK16;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_8_8_8_8:begin
   case aFormat of
    GL_RGB,GL_BGRA:begin
     result:=VK_FORMAT_R8G8B8A8_UNORM;
    end;
    GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_R8G8B8A8_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_8_8_8_8_REV:begin
   case aFormat of
    GL_RGB,GL_BGRA:begin
     result:=VK_FORMAT_A8B8G8R8_UNORM_PACK32;
    end;
    GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_A8B8G8R8_UINT_PACK32;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_10_10_10_2:begin
   case aFormat of
    GL_RGB,GL_BGRA:begin
     result:=VK_FORMAT_A2R10G10B10_UNORM_PACK32;
    end;
    GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_A2R10G10B10_UINT_PACK32;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_2_10_10_10_REV:begin
   case aFormat of
    GL_RGB,GL_BGRA:begin
     result:=VK_FORMAT_A2B10G10R10_UINT_PACK32;
    end;
    GL_RGB_INTEGER,GL_BGRA_INTEGER:begin
     result:=VK_FORMAT_A2B10G10R10_UNORM_PACK32;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_10F_11F_11F_REV:begin
   case aFormat of
    GL_RGB,GL_BGR:begin
     result:=VK_FORMAT_B10G11R11_UFLOAT_PACK32;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_5_9_9_9_REV:begin
   case aFormat of
    GL_RGB,GL_BGR:begin
     result:=VK_FORMAT_E5B9G9R9_UFLOAT_PACK32;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT_24_8:begin
   case aFormat of
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_D24_UNORM_S8_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_FLOAT_32_UNSIGNED_INT_24_8_REV:begin
   case aFormat of
    GL_DEPTH_STENCIL:begin
     result:=VK_FORMAT_D32_SFLOAT_S8_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  else begin
   result:=VK_FORMAT_UNDEFINED;
  end;
 end;
end;

function VulkanGetFormatFromOpenGLType(const aType,aNumComponents:TpvUInt32;const aNormalized:boolean):TVkFormat;
begin
 case aType of
  GL_UNSIGNED_BYTE:begin
   case aNumComponents of
    1:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8_UNORM;
     end else begin
      result:=VK_FORMAT_R8_UINT;
     end;
    end;
    2:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8G8_UNORM;
     end else begin
      result:=VK_FORMAT_R8G8_UINT;
     end;
    end;
    3:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8G8B8_UNORM;
     end else begin
      result:=VK_FORMAT_R8G8B8_UINT;
     end;
    end;
    4:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8G8B8A8_UNORM;
     end else begin
      result:=VK_FORMAT_R8G8B8A8_UINT;
     end;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_BYTE:begin
   case aNumComponents of
    1:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8_SNORM;
     end else begin
      result:=VK_FORMAT_R8_SINT;
     end;
    end;
    2:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8G8_SNORM;
     end else begin
      result:=VK_FORMAT_R8G8_SINT;
     end;
    end;
    3:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8G8B8_SNORM;
     end else begin
      result:=VK_FORMAT_R8G8B8_SINT;
     end;
    end;
    4:begin
     if aNormalized then begin
      result:=VK_FORMAT_R8G8B8A8_SNORM;
     end else begin
      result:=VK_FORMAT_R8G8B8A8_SINT;
     end;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_SHORT:begin
   case aNumComponents of
    1:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16_UNORM;
     end else begin
      result:=VK_FORMAT_R16_UINT;
     end;
    end;
    2:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16G16_UNORM;
     end else begin
      result:=VK_FORMAT_R16G16_UINT;
     end;
    end;
    3:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16G16B16_UNORM;
     end else begin
      result:=VK_FORMAT_R16G16B16_UINT;
     end;
    end;
    4:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16G16B16A16_UNORM;
     end else begin
      result:=VK_FORMAT_R16G16B16A16_UINT;
     end;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_SHORT:begin
   case aNumComponents of
    1:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16_SNORM;
     end else begin
      result:=VK_FORMAT_R16_SINT;
     end;
    end;
    2:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16G16_SNORM;
     end else begin
      result:=VK_FORMAT_R16G16_SINT;
     end;
    end;
    3:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16G16B16_SNORM;
     end else begin
      result:=VK_FORMAT_R16G16B16_SINT;
     end;
    end;
    4:begin
     if aNormalized then begin
      result:=VK_FORMAT_R16G16B16A16_SNORM;
     end else begin
      result:=VK_FORMAT_R16G16B16A16_SINT;
     end;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_HALF_FLOAT,GL_HALF_FLOAT_OES:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R16_SFLOAT;
    end;
    2:begin
     result:=VK_FORMAT_R16G16_SFLOAT;
    end;
    3:begin
     result:=VK_FORMAT_R16G16B16_SFLOAT;
    end;
    4:begin
     result:=VK_FORMAT_R16G16B16A16_SFLOAT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R32_UINT;
    end;
    2:begin
     result:=VK_FORMAT_R32G32_UINT;
    end;
    3:begin
     result:=VK_FORMAT_R32G32B32_UINT;
    end;
    4:begin
     result:=VK_FORMAT_R32G32B32A32_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_INT:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R32_SINT;
    end;
    2:begin
     result:=VK_FORMAT_R32G32_SINT;
    end;
    3:begin
     result:=VK_FORMAT_R32G32B32_SINT;
    end;
    4:begin
     result:=VK_FORMAT_R32G32B32A32_SINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_FLOAT:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R32_SFLOAT;
    end;
    2:begin
     result:=VK_FORMAT_R32G32_SFLOAT;
    end;
    3:begin
     result:=VK_FORMAT_R32G32B32_SFLOAT;
    end;
    4:begin
     result:=VK_FORMAT_R32G32B32A32_SFLOAT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_INT64:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R64_UINT;
    end;
    2:begin
     result:=VK_FORMAT_R64G64_UINT;
    end;
    3:begin
     result:=VK_FORMAT_R64G64B64_UINT;
    end;
    4:begin
     result:=VK_FORMAT_R64G64B64A64_UINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_INT64:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R64_SINT;
    end;
    2:begin
     result:=VK_FORMAT_R64G64_SINT;
    end;
    3:begin
     result:=VK_FORMAT_R64G64B64_SINT;
    end;
    4:begin
     result:=VK_FORMAT_R64G64B64A64_SINT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_DOUBLE:begin
   case aNumComponents of
    1:begin
     result:=VK_FORMAT_R64_SFLOAT;
    end;
    2:begin
     result:=VK_FORMAT_R64G64_SFLOAT;
    end;
    3:begin
     result:=VK_FORMAT_R64G64B64_SFLOAT;
    end;
    4:begin
     result:=VK_FORMAT_R64G64B64A64_SFLOAT;
    end;
    else begin
     result:=VK_FORMAT_UNDEFINED;
    end;
   end;
  end;
  GL_UNSIGNED_BYTE_3_3_2:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_UNSIGNED_BYTE_2_3_3_REV:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_UNSIGNED_SHORT_5_6_5:begin
   result:=VK_FORMAT_R5G6B5_UNORM_PACK16;
  end;
  GL_UNSIGNED_SHORT_5_6_5_REV:begin
   result:=VK_FORMAT_B5G6R5_UNORM_PACK16;
  end;
  GL_UNSIGNED_SHORT_4_4_4_4:begin
   result:=VK_FORMAT_R4G4B4A4_UNORM_PACK16;
  end;
  GL_UNSIGNED_SHORT_4_4_4_4_REV:begin
   result:=VK_FORMAT_B4G4R4A4_UNORM_PACK16;
  end;
  GL_UNSIGNED_SHORT_5_5_5_1:begin
   result:=VK_FORMAT_R5G5B5A1_UNORM_PACK16;
  end;
  GL_UNSIGNED_SHORT_1_5_5_5_REV:begin
   result:=VK_FORMAT_A1R5G5B5_UNORM_PACK16;
  end;
  GL_UNSIGNED_INT_8_8_8_8:begin
   if aNormalized then begin
    result:=VK_FORMAT_R8G8B8A8_UNORM;
   end else begin
    result:=VK_FORMAT_R8G8B8A8_UINT;
   end;
  end;
  GL_UNSIGNED_INT_8_8_8_8_REV:begin
   if aNormalized then begin
    result:=VK_FORMAT_A8B8G8R8_UNORM_PACK32;
   end else begin
    result:=VK_FORMAT_A8B8G8R8_UINT_PACK32;
   end;
  end;
  GL_UNSIGNED_INT_10_10_10_2:begin
   if aNormalized then begin
    result:=VK_FORMAT_A2R10G10B10_UNORM_PACK32;
   end else begin
    result:=VK_FORMAT_A2R10G10B10_UINT_PACK32;
   end;
  end;
  GL_UNSIGNED_INT_2_10_10_10_REV:begin
   if aNormalized then begin
    result:=VK_FORMAT_A2B10G10R10_UNORM_PACK32;
   end else begin
    result:=VK_FORMAT_A2B10G10R10_UINT_PACK32;
   end;
  end;
  GL_UNSIGNED_INT_10F_11F_11F_REV:begin
   result:=VK_FORMAT_B10G11R11_UFLOAT_PACK32;
  end;
  GL_UNSIGNED_INT_5_9_9_9_REV:begin
   result:=VK_FORMAT_E5B9G9R9_UFLOAT_PACK32;
  end;
  GL_UNSIGNED_INT_24_8:begin
   result:=VK_FORMAT_D24_UNORM_S8_UINT;
  end;
  GL_FLOAT_32_UNSIGNED_INT_24_8_REV:begin
   result:=VK_FORMAT_D32_SFLOAT_S8_UINT;
  end;
  else begin
   result:=VK_FORMAT_UNDEFINED;
  end;
 end;
end;

function VulkanGetFormatFromOpenGLInternalFormat(const aInternalFormat:TpvUInt32):TVkFormat;
begin
 case aInternalFormat of
  GL_R8:begin
   result:=VK_FORMAT_R8_UNORM; // 1-component, 8-bit unsigned normalized
  end;
  GL_RG8:begin
   result:=VK_FORMAT_R8G8_UNORM; // 2-component, 8-bit unsigned normalized
  end;
  GL_RGB8:begin
   result:=VK_FORMAT_R8G8B8_UNORM; // 3-component, 8-bit unsigned normalized
  end;
  GL_RGBA8:begin
   result:=VK_FORMAT_R8G8B8A8_UNORM; // 4-component, 8-bit unsigned normalized
  end;
  GL_R8_SNORM:begin
   result:=VK_FORMAT_R8_SNORM; // 1-component, 8-bit signed normalized
  end;
  GL_RG8_SNORM:begin
   result:=VK_FORMAT_R8G8_SNORM; // 2-component, 8-bit signed normalized
  end;
  GL_RGB8_SNORM:begin
   result:=VK_FORMAT_R8G8B8_SNORM; // 3-component, 8-bit signed normalized
  end;
  GL_RGBA8_SNORM:begin
   result:=VK_FORMAT_R8G8B8A8_SNORM; // 4-component, 8-bit signed normalized
  end;
  GL_R8UI:begin
   result:=VK_FORMAT_R8_UINT; // 1-component, 8-bit unsigned integer
  end;
  GL_RG8UI:begin
   result:=VK_FORMAT_R8G8_UINT; // 2-component, 8-bit unsigned integer
  end;
  GL_RGB8UI:begin
   result:=VK_FORMAT_R8G8B8_UINT; // 3-component, 8-bit unsigned integer
  end;
  GL_RGBA8UI:begin
   result:=VK_FORMAT_R8G8B8A8_UINT; // 4-component, 8-bit unsigned integer
  end;
  GL_R8I:begin
   result:=VK_FORMAT_R8_SINT; // 1-component, 8-bit signed integer
  end;
  GL_RG8I:begin
   result:=VK_FORMAT_R8G8_SINT; // 2-component, 8-bit signed integer
  end;
  GL_RGB8I:begin
   result:=VK_FORMAT_R8G8B8_SINT; // 3-component, 8-bit signed integer
  end;
  GL_RGBA8I:begin
   result:=VK_FORMAT_R8G8B8A8_SINT; // 4-component, 8-bit signed integer
  end;
  GL_SR8:begin
   result:=VK_FORMAT_R8_SRGB; // 1-component, 8-bit sRGB
  end;
  GL_SRG8:begin
   result:=VK_FORMAT_R8G8_SRGB; // 2-component, 8-bit sRGB
  end;
  GL_SRGB8:begin
   result:=VK_FORMAT_R8G8B8_SRGB; // 3-component, 8-bit sRGB
  end;
  GL_SRGB8_ALPHA8:begin
   result:=VK_FORMAT_R8G8B8A8_SRGB; // 4-component, 8-bit sRGB
  end;
  GL_R16:begin
   result:=VK_FORMAT_R16_UNORM; // 1-component, 16-bit unsigned normalized
  end;
  GL_RG16:begin
   result:=VK_FORMAT_R16G16_UNORM; // 2-component, 16-bit unsigned normalized
  end;
  GL_RGB16:begin
   result:=VK_FORMAT_R16G16B16_UNORM; // 3-component, 16-bit unsigned normalized
  end;
  GL_RGBA16:begin
   result:=VK_FORMAT_R16G16B16A16_UNORM; // 4-component, 16-bit unsigned normalized
  end;
  GL_R16_SNORM:begin
   result:=VK_FORMAT_R16_SNORM; // 1-component, 16-bit signed normalized
  end;
  GL_RG16_SNORM:begin
   result:=VK_FORMAT_R16G16_SNORM; // 2-component, 16-bit signed normalized
  end;
  GL_RGB16_SNORM:begin
   result:=VK_FORMAT_R16G16B16_SNORM; // 3-component, 16-bit signed normalized
  end;
  GL_RGBA16_SNORM:begin
   result:=VK_FORMAT_R16G16B16A16_SNORM; // 4-component, 16-bit signed normalized
  end;
  GL_R16UI:begin
   result:=VK_FORMAT_R16_UINT; // 1-component, 16-bit unsigned integer
  end;
  GL_RG16UI:begin
   result:=VK_FORMAT_R16G16_UINT; // 2-component, 16-bit unsigned integer
  end;
  GL_RGB16UI:begin
   result:=VK_FORMAT_R16G16B16_UINT; // 3-component, 16-bit unsigned integer
  end;
  GL_RGBA16UI:begin
   result:=VK_FORMAT_R16G16B16A16_UINT; // 4-component, 16-bit unsigned integer
  end;
  GL_R16I:begin
   result:=VK_FORMAT_R16_SINT; // 1-component, 16-bit signed integer
  end;
  GL_RG16I:begin
   result:=VK_FORMAT_R16G16_SINT; // 2-component, 16-bit signed integer
  end;
  GL_RGB16I:begin
   result:=VK_FORMAT_R16G16B16_SINT; // 3-component, 16-bit signed integer
  end;
  GL_RGBA16I:begin
   result:=VK_FORMAT_R16G16B16A16_SINT; // 4-component, 16-bit signed integer
  end;
  GL_R16F:begin
   result:=VK_FORMAT_R16_SFLOAT; // 1-component, 16-bit floating-point
  end;
  GL_RG16F:begin
   result:=VK_FORMAT_R16G16_SFLOAT; // 2-component, 16-bit floating-point
  end;
  GL_RGB16F:begin
   result:=VK_FORMAT_R16G16B16_SFLOAT; // 3-component, 16-bit floating-point
  end;
  GL_RGBA16F:begin
   result:=VK_FORMAT_R16G16B16A16_SFLOAT; // 4-component, 16-bit floating-point
  end;
  GL_R32UI:begin
   result:=VK_FORMAT_R32_UINT; // 1-component, 32-bit unsigned integer
  end;
  GL_RG32UI:begin
   result:=VK_FORMAT_R32G32_UINT; // 2-component, 32-bit unsigned integer
  end;
  GL_RGB32UI:begin
   result:=VK_FORMAT_R32G32B32_UINT; // 3-component, 32-bit unsigned integer
  end;
  GL_RGBA32UI:begin
   result:=VK_FORMAT_R32G32B32A32_UINT; // 4-component, 32-bit unsigned integer
  end;
  GL_R32I:begin
   result:=VK_FORMAT_R32_SINT; // 1-component, 32-bit signed integer
  end;
  GL_RG32I:begin
   result:=VK_FORMAT_R32G32_SINT; // 2-component, 32-bit signed integer
  end;
  GL_RGB32I:begin
   result:=VK_FORMAT_R32G32B32_SINT; // 3-component, 32-bit signed integer
  end;
  GL_RGBA32I:begin
   result:=VK_FORMAT_R32G32B32A32_SINT; // 4-component, 32-bit signed integer
  end;
  GL_R32F:begin
   result:=VK_FORMAT_R32_SFLOAT; // 1-component, 32-bit floating-point
  end;
  GL_RG32F:begin
   result:=VK_FORMAT_R32G32_SFLOAT; // 2-component, 32-bit floating-point
  end;
  GL_RGB32F:begin
   result:=VK_FORMAT_R32G32B32_SFLOAT; // 3-component, 32-bit floating-point
  end;
  GL_RGBA32F:begin
   result:=VK_FORMAT_R32G32B32A32_SFLOAT; // 4-component, 32-bit floating-point
  end;
  GL_R3_G3_B2:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 3:3:2, unsigned normalized
  end;
  GL_RGB4:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 4:4:4, unsigned normalized
  end;
  GL_RGB5:begin
   result:=VK_FORMAT_R5G5B5A1_UNORM_PACK16; // 3-component 5:5:5, unsigned normalized
  end;
  GL_RGB565:begin
   result:=VK_FORMAT_R5G6B5_UNORM_PACK16; // 3-component 5:6:5, unsigned normalized
  end;
  GL_RGB10:begin
   result:=VK_FORMAT_A2R10G10B10_UNORM_PACK32; // 3-component 10:10:10, unsigned normalized
  end;
  GL_RGB12:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 12:12:12, unsigned normalized
  end;
  GL_RGBA2:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 2:2:2:2, unsigned normalized
  end;
  GL_RGBA4:begin
   result:=VK_FORMAT_R4G4B4A4_UNORM_PACK16; // 4-component 4:4:4:4, unsigned normalized
  end;
  GL_RGBA12:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 12:12:12:12, unsigned normalized
  end;
  GL_RGB5_A1:begin
   result:=VK_FORMAT_A1R5G5B5_UNORM_PACK16; // 4-component 5:5:5:1, unsigned normalized
  end;
  GL_RGB10_A2:begin
   result:=VK_FORMAT_A2R10G10B10_UNORM_PACK32; // 4-component 10:10:10:2, unsigned normalized
  end;
  GL_RGB10_A2UI:begin
   result:=VK_FORMAT_A2R10G10B10_UINT_PACK32; // 4-component 10:10:10:2, unsigned integer
  end;
  GL_R11F_G11F_B10F:begin
   result:=VK_FORMAT_B10G11R11_UFLOAT_PACK32; // 3-component 11:11:10, floating-point
  end;
  GL_RGB9_E5:begin
   result:=VK_FORMAT_E5B9G9R9_UFLOAT_PACK32; // 3-component/exp 9:9:9/5, floating-point
  end;
  GL_COMPRESSED_RGB_S3TC_DXT1_EXT:begin
   result:=VK_FORMAT_BC1_RGB_UNORM_BLOCK; // line through 3D space, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_S3TC_DXT1_EXT:begin
   result:=VK_FORMAT_BC1_RGBA_UNORM_BLOCK; // line through 3D space plus 1-bit alpha, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_S3TC_DXT5_EXT:begin
   result:=VK_FORMAT_BC2_UNORM_BLOCK; // line through 3D space plus line through 1D space, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_S3TC_DXT3_EXT:begin
   result:=VK_FORMAT_BC3_UNORM_BLOCK; // line through 3D space plus 4-bit alpha, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SRGB_S3TC_DXT1_EXT:begin
   result:=VK_FORMAT_BC1_RGB_SRGB_BLOCK; // line through 3D space, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT:begin
   result:=VK_FORMAT_BC1_RGBA_SRGB_BLOCK; // line through 3D space plus 1-bit alpha, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT:begin
   result:=VK_FORMAT_BC2_SRGB_BLOCK; // line through 3D space plus line through 1D space, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT:begin
   result:=VK_FORMAT_BC3_SRGB_BLOCK; // line through 3D space plus 4-bit alpha, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_LUMINANCE_LATC1_EXT:begin
   result:=VK_FORMAT_BC4_UNORM_BLOCK; // line through 1D space, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT:begin
   result:=VK_FORMAT_BC5_UNORM_BLOCK; // two lines through 1D space, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SIGNED_LUMINANCE_LATC1_EXT:begin
   result:=VK_FORMAT_BC4_SNORM_BLOCK; // line through 1D space, 4x4 blocks, signed normalized
  end;
  GL_COMPRESSED_SIGNED_LUMINANCE_ALPHA_LATC2_EXT:begin
   result:=VK_FORMAT_BC5_SNORM_BLOCK; // two lines through 1D space, 4x4 blocks, signed normalized
  end;
  GL_COMPRESSED_RED_RGTC1:begin
   result:=VK_FORMAT_BC4_UNORM_BLOCK; // line through 1D space, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RG_RGTC2:begin
   result:=VK_FORMAT_BC5_UNORM_BLOCK; // two lines through 1D space, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SIGNED_RED_RGTC1:begin
   result:=VK_FORMAT_BC4_SNORM_BLOCK; // line through 1D space, 4x4 blocks, signed normalized
  end;
  GL_COMPRESSED_SIGNED_RG_RGTC2:begin
   result:=VK_FORMAT_BC5_SNORM_BLOCK; // two lines through 1D space, 4x4 blocks, signed normalized
  end;
  GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT:begin
   result:=VK_FORMAT_BC6H_UFLOAT_BLOCK; // 3-component, 4x4 blocks, unsigned floating-point
  end;
  GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT:begin
   result:=VK_FORMAT_BC6H_SFLOAT_BLOCK; // 3-component, 4x4 blocks, signed floating-point
  end;
  GL_COMPRESSED_RGBA_BPTC_UNORM:begin
   result:=VK_FORMAT_BC7_UNORM_BLOCK; // 4-component, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM:begin
   result:=VK_FORMAT_BC7_SRGB_BLOCK; // 4-component, 4x4 blocks, sRGB
  end;
  GL_ETC1_RGB8_OES:begin
   result:=VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK; // 3-component ETC1, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGB8_ETC2:begin
   result:=VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK; // 3-component ETC2, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2:begin
   result:=VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK; // 4-component ETC2 with 1-bit alpha, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA8_ETC2_EAC:begin
   result:=VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK; // 4-component ETC2, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SRGB8_ETC2:begin
   result:=VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK; // 3-component ETC2, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2:begin
   result:=VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK; // 4-component ETC2 with 1-bit alpha, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:begin
   result:=VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK; // 4-component ETC2, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_R11_EAC:begin
   result:=VK_FORMAT_EAC_R11_UNORM_BLOCK; // 1-component ETC, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RG11_EAC:begin
   result:=VK_FORMAT_EAC_R11G11_UNORM_BLOCK; // 2-component ETC, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SIGNED_R11_EAC:begin
   result:=VK_FORMAT_EAC_R11_SNORM_BLOCK; // 1-component ETC, 4x4 blocks, signed normalized
  end;
  GL_COMPRESSED_SIGNED_RG11_EAC:begin
   result:=VK_FORMAT_EAC_R11G11_SNORM_BLOCK; // 2-component ETC, 4x4 blocks, signed normalized
  end;
  GL_COMPRESSED_RGB_PVRTC_4BPPV1_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component PVRTC, 16x8 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGB_PVRTC_2BPPV1_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component PVRTC, 8x8 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_PVRTC_4BPPV1_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 16x8 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_PVRTC_2BPPV1_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 8x8 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_PVRTC_2BPPV2_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 8x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_PVRTC_4BPPV2_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SRGB_PVRTC_2BPPV1_EXT:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component PVRTC, 16x8 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_PVRTC_4BPPV1_EXT:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component PVRTC, 8x8 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV1_EXT:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 16x8 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV1_EXT:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 8x8 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_PVRTC_2BPPV2_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 8x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB_ALPHA_PVRTC_4BPPV2_IMG:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component PVRTC, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_RGBA_ASTC_4x4_KHR:begin
   result:=VK_FORMAT_ASTC_4x4_UNORM_BLOCK; // 4-component ASTC, 4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_5x4_KHR:begin
   result:=VK_FORMAT_ASTC_5x4_UNORM_BLOCK; // 4-component ASTC, 5x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_5x5_KHR:begin
   result:=VK_FORMAT_ASTC_5x5_UNORM_BLOCK; // 4-component ASTC, 5x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_6x5_KHR:begin
   result:=VK_FORMAT_ASTC_6x5_UNORM_BLOCK; // 4-component ASTC, 6x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_6x6_KHR:begin
   result:=VK_FORMAT_ASTC_6x6_UNORM_BLOCK; // 4-component ASTC, 6x6 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_8x5_KHR:begin
   result:=VK_FORMAT_ASTC_8x5_UNORM_BLOCK; // 4-component ASTC, 8x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_8x6_KHR:begin
   result:=VK_FORMAT_ASTC_8x6_UNORM_BLOCK; // 4-component ASTC, 8x6 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_8x8_KHR:begin
   result:=VK_FORMAT_ASTC_8x8_UNORM_BLOCK; // 4-component ASTC, 8x8 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_10x5_KHR:begin
   result:=VK_FORMAT_ASTC_10x5_UNORM_BLOCK; // 4-component ASTC, 10x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_10x6_KHR:begin
   result:=VK_FORMAT_ASTC_10x6_UNORM_BLOCK; // 4-component ASTC, 10x6 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_10x8_KHR:begin
   result:=VK_FORMAT_ASTC_10x8_UNORM_BLOCK; // 4-component ASTC, 10x8 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_10x10_KHR:begin
   result:=VK_FORMAT_ASTC_10x10_UNORM_BLOCK; // 4-component ASTC, 10x10 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_12x10_KHR:begin
   result:=VK_FORMAT_ASTC_12x10_UNORM_BLOCK; // 4-component ASTC, 12x10 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_12x12_KHR:begin
   result:=VK_FORMAT_ASTC_12x12_UNORM_BLOCK; // 4-component ASTC, 12x12 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR:begin
   result:=VK_FORMAT_ASTC_4x4_SRGB_BLOCK; // 4-component ASTC, 4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR:begin
   result:=VK_FORMAT_ASTC_5x4_SRGB_BLOCK; // 4-component ASTC, 5x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR:begin
   result:=VK_FORMAT_ASTC_5x5_SRGB_BLOCK; // 4-component ASTC, 5x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR:begin
   result:=VK_FORMAT_ASTC_6x5_SRGB_BLOCK; // 4-component ASTC, 6x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR:begin
   result:=VK_FORMAT_ASTC_6x6_SRGB_BLOCK; // 4-component ASTC, 6x6 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR:begin
   result:=VK_FORMAT_ASTC_8x5_SRGB_BLOCK; // 4-component ASTC, 8x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR:begin
   result:=VK_FORMAT_ASTC_8x6_SRGB_BLOCK; // 4-component ASTC, 8x6 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR:begin
   result:=VK_FORMAT_ASTC_8x8_SRGB_BLOCK; // 4-component ASTC, 8x8 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR:begin
   result:=VK_FORMAT_ASTC_10x5_SRGB_BLOCK; // 4-component ASTC, 10x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR:begin
   result:=VK_FORMAT_ASTC_10x6_SRGB_BLOCK; // 4-component ASTC, 10x6 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR:begin
   result:=VK_FORMAT_ASTC_10x8_SRGB_BLOCK; // 4-component ASTC, 10x8 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR:begin
   result:=VK_FORMAT_ASTC_10x10_SRGB_BLOCK; // 4-component ASTC, 10x10 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR:begin
   result:=VK_FORMAT_ASTC_12x10_SRGB_BLOCK; // 4-component ASTC, 12x10 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR:begin
   result:=VK_FORMAT_ASTC_12x12_SRGB_BLOCK; // 4-component ASTC, 12x12 blocks, sRGB
  end;
  GL_COMPRESSED_RGBA_ASTC_3x3x3_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 3x3x3 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_4x3x3_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 4x3x3 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_4x4x3_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 4x4x3 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_4x4x4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 4x4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_5x4x4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 5x4x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_5x5x4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 5x5x4 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_5x5x5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 5x5x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_6x5x5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 6x5x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_6x6x5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 6x6x5 blocks, unsigned normalized
  end;
  GL_COMPRESSED_RGBA_ASTC_6x6x6_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 6x6x6 blocks, unsigned normalized
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_3x3x3_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 3x3x3 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x3x3_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 4x3x3 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4x3_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 4x4x3 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4x4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 4x4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4x4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 5x4x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5x4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 5x5x4 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5x5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 5x5x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5x5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 6x5x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6x5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 6x6x5 blocks, sRGB
  end;
  GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6x6_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component ASTC, 6x6x6 blocks, sRGB
  end;
  GL_ATC_RGB_AMD:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component, 4x4 blocks, unsigned normalized
  end;
  GL_ATC_RGBA_EXPLICIT_ALPHA_AMD:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component, 4x4 blocks, unsigned normalized
  end;
  GL_ATC_RGBA_INTERPOLATED_ALPHA_AMD:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component, 4x4 blocks, unsigned normalized
  end;
  GL_PALETTE4_RGB8_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 8:8:8, 4-bit palette, unsigned normalized
  end;
  GL_PALETTE4_RGBA8_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 8:8:8:8, 4-bit palette, unsigned normalized
  end;
  GL_PALETTE4_R5_G6_B5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 5:6:5, 4-bit palette, unsigned normalized
  end;
  GL_PALETTE4_RGBA4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 4:4:4:4, 4-bit palette, unsigned normalized
  end;
  GL_PALETTE4_RGB5_A1_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 5:5:5:1, 4-bit palette, unsigned normalized
  end;
  GL_PALETTE8_RGB8_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 8:8:8, 8-bit palette, unsigned normalized
  end;
  GL_PALETTE8_RGBA8_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 8:8:8:8, 8-bit palette, unsigned normalized
  end;
  GL_PALETTE8_R5_G6_B5_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 3-component 5:6:5, 8-bit palette, unsigned normalized
  end;
  GL_PALETTE8_RGBA4_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 4:4:4:4, 8-bit palette, unsigned normalized
  end;
  GL_PALETTE8_RGB5_A1_OES:begin
   result:=VK_FORMAT_UNDEFINED; // 4-component 5:5:5:1, 8-bit palette, unsigned normalized
  end;
  GL_DEPTH_COMPONENT16:begin
   result:=VK_FORMAT_D16_UNORM;
  end;
  GL_DEPTH_COMPONENT24:begin
   result:=VK_FORMAT_X8_D24_UNORM_PACK32;
  end;
  GL_DEPTH_COMPONENT32:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_DEPTH_COMPONENT32F:begin
   result:=VK_FORMAT_D32_SFLOAT;
  end;
  GL_DEPTH_COMPONENT32F_NV:begin
   result:=VK_FORMAT_D32_SFLOAT;
  end;
  GL_STENCIL_INDEX1:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_STENCIL_INDEX4:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_STENCIL_INDEX8:begin
   result:=VK_FORMAT_S8_UINT;
  end;
  GL_STENCIL_INDEX16:begin
   result:=VK_FORMAT_UNDEFINED;
  end;
  GL_DEPTH24_STENCIL8:begin
   result:=VK_FORMAT_D24_UNORM_S8_UINT;
  end;
  GL_DEPTH32F_STENCIL8:begin
   result:=VK_FORMAT_D32_SFLOAT_S8_UINT;
  end;
  GL_DEPTH32F_STENCIL8_NV:begin
   result:=VK_FORMAT_D32_SFLOAT_S8_UINT;
  end;
  else begin
   result:=VK_FORMAT_UNDEFINED;
  end;
 end;
end;

function VulkanGetFormatSize(const aFormat:TVkFormat):TpvVulkanFormatSize;
begin
 case aFormat of
  VK_FORMAT_R4G4_UNORM_PACK8:begin
   result.Flags:=[vfsfPacked];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=1*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R4G4B4A4_UNORM_PACK16,VK_FORMAT_B4G4R4A4_UNORM_PACK16,VK_FORMAT_R5G6B5_UNORM_PACK16,VK_FORMAT_B5G6R5_UNORM_PACK16,VK_FORMAT_R5G5B5A1_UNORM_PACK16,VK_FORMAT_B5G5R5A1_UNORM_PACK16,VK_FORMAT_A1R5G5B5_UNORM_PACK16:begin
   result.Flags:=[vfsfPacked];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=2*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R8_UNORM,VK_FORMAT_R8_SNORM,VK_FORMAT_R8_USCALED,VK_FORMAT_R8_SSCALED,VK_FORMAT_R8_UINT,VK_FORMAT_R8_SINT,VK_FORMAT_R8_SRGB:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=1*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R8G8_UNORM,VK_FORMAT_R8G8_SNORM,VK_FORMAT_R8G8_USCALED,VK_FORMAT_R8G8_SSCALED,VK_FORMAT_R8G8_UINT,VK_FORMAT_R8G8_SINT,VK_FORMAT_R8G8_SRGB:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=2*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R8G8B8_UNORM,VK_FORMAT_R8G8B8_SNORM,VK_FORMAT_R8G8B8_USCALED,VK_FORMAT_R8G8B8_SSCALED,VK_FORMAT_R8G8B8_UINT,VK_FORMAT_R8G8B8_SINT,VK_FORMAT_R8G8B8_SRGB,VK_FORMAT_B8G8R8_UNORM,VK_FORMAT_B8G8R8_SNORM,VK_FORMAT_B8G8R8_USCALED,VK_FORMAT_B8G8R8_SSCALED,VK_FORMAT_B8G8R8_UINT,VK_FORMAT_B8G8R8_SINT,VK_FORMAT_B8G8R8_SRGB:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=3*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R8G8B8A8_UNORM,
  VK_FORMAT_R8G8B8A8_SNORM,VK_FORMAT_R8G8B8A8_USCALED,VK_FORMAT_R8G8B8A8_SSCALED,VK_FORMAT_R8G8B8A8_UINT,VK_FORMAT_R8G8B8A8_SINT,VK_FORMAT_R8G8B8A8_SRGB,VK_FORMAT_B8G8R8A8_UNORM,VK_FORMAT_B8G8R8A8_SNORM,VK_FORMAT_B8G8R8A8_USCALED,VK_FORMAT_B8G8R8A8_SSCALED,VK_FORMAT_B8G8R8A8_UINT,VK_FORMAT_B8G8R8A8_SINT,VK_FORMAT_B8G8R8A8_SRGB:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_A8B8G8R8_UNORM_PACK32,VK_FORMAT_A8B8G8R8_SNORM_PACK32,VK_FORMAT_A8B8G8R8_USCALED_PACK32,VK_FORMAT_A8B8G8R8_SSCALED_PACK32,VK_FORMAT_A8B8G8R8_UINT_PACK32,VK_FORMAT_A8B8G8R8_SINT_PACK32,VK_FORMAT_A8B8G8R8_SRGB_PACK32:begin
   result.Flags:=[vfsfPacked];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_A2R10G10B10_UNORM_PACK32,VK_FORMAT_A2R10G10B10_SNORM_PACK32,VK_FORMAT_A2R10G10B10_USCALED_PACK32,VK_FORMAT_A2R10G10B10_SSCALED_PACK32,VK_FORMAT_A2R10G10B10_UINT_PACK32,VK_FORMAT_A2R10G10B10_SINT_PACK32,VK_FORMAT_A2B10G10R10_UNORM_PACK32,VK_FORMAT_A2B10G10R10_SNORM_PACK32,VK_FORMAT_A2B10G10R10_USCALED_PACK32,VK_FORMAT_A2B10G10R10_SSCALED_PACK32,VK_FORMAT_A2B10G10R10_UINT_PACK32,VK_FORMAT_A2B10G10R10_SINT_PACK32:begin
   result.Flags:=[vfsfPacked];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R16_UNORM,VK_FORMAT_R16_SNORM,VK_FORMAT_R16_USCALED,VK_FORMAT_R16_SSCALED,VK_FORMAT_R16_UINT,VK_FORMAT_R16_SINT,VK_FORMAT_R16_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=2*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R16G16_UNORM,VK_FORMAT_R16G16_SNORM,VK_FORMAT_R16G16_USCALED,VK_FORMAT_R16G16_SSCALED,VK_FORMAT_R16G16_UINT,VK_FORMAT_R16G16_SINT,VK_FORMAT_R16G16_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R16G16B16_UNORM,VK_FORMAT_R16G16B16_SNORM,VK_FORMAT_R16G16B16_USCALED,VK_FORMAT_R16G16B16_SSCALED,VK_FORMAT_R16G16B16_UINT,VK_FORMAT_R16G16B16_SINT,VK_FORMAT_R16G16B16_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=6*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R16G16B16A16_UNORM,VK_FORMAT_R16G16B16A16_SNORM,VK_FORMAT_R16G16B16A16_USCALED,VK_FORMAT_R16G16B16A16_SSCALED,VK_FORMAT_R16G16B16A16_UINT,VK_FORMAT_R16G16B16A16_SINT,VK_FORMAT_R16G16B16A16_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=8*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R32_UINT,VK_FORMAT_R32_SINT,VK_FORMAT_R32_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R32G32_UINT,VK_FORMAT_R32G32_SINT,VK_FORMAT_R32G32_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=8*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R32G32B32_UINT,VK_FORMAT_R32G32B32_SINT,VK_FORMAT_R32G32B32_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=12*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R32G32B32A32_UINT,VK_FORMAT_R32G32B32A32_SINT,VK_FORMAT_R32G32B32A32_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R64_UINT,VK_FORMAT_R64_SINT,VK_FORMAT_R64_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=8*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R64G64_UINT,VK_FORMAT_R64G64_SINT,VK_FORMAT_R64G64_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R64G64B64_UINT,VK_FORMAT_R64G64B64_SINT,VK_FORMAT_R64G64B64_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=24*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_R64G64B64A64_UINT,VK_FORMAT_R64G64B64A64_SINT,VK_FORMAT_R64G64B64A64_SFLOAT:begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=32*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_B10G11R11_UFLOAT_PACK32,VK_FORMAT_E5B9G9R9_UFLOAT_PACK32:begin
   result.Flags:=[vfsfPacked];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_D16_UNORM:begin
   result.Flags:=[vfsfDepth];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=2*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_X8_D24_UNORM_PACK32:begin
   result.Flags:=[vfsfPacked,vfsfDepth];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_D32_SFLOAT:begin
   result.Flags:=[vfsfDepth];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_S8_UINT:begin
   result.Flags:=[vfsfStencil];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=1*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_D16_UNORM_S8_UINT:begin
   result.Flags:=[vfsfDepth,vfsfStencil];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=3*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_D24_UNORM_S8_UINT:begin
   result.Flags:=[vfsfDepth,vfsfStencil];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=4*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_D32_SFLOAT_S8_UINT:begin
   result.Flags:=[vfsfDepth,vfsfStencil];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=8*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_BC1_RGB_UNORM_BLOCK,VK_FORMAT_BC1_RGB_SRGB_BLOCK,VK_FORMAT_BC1_RGBA_UNORM_BLOCK,VK_FORMAT_BC1_RGBA_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=8*8;
   result.BlockWidth:=4;
   result.BlockHeight:=4;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_BC2_UNORM_BLOCK,VK_FORMAT_BC2_SRGB_BLOCK,VK_FORMAT_BC3_UNORM_BLOCK,VK_FORMAT_BC3_SRGB_BLOCK,VK_FORMAT_BC4_UNORM_BLOCK,VK_FORMAT_BC4_SNORM_BLOCK,VK_FORMAT_BC5_UNORM_BLOCK,VK_FORMAT_BC5_SNORM_BLOCK,VK_FORMAT_BC6H_UFLOAT_BLOCK,VK_FORMAT_BC6H_SFLOAT_BLOCK,VK_FORMAT_BC7_UNORM_BLOCK,VK_FORMAT_BC7_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=4;
   result.BlockHeight:=4;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK,VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK,VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK,VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=8*8;
   result.BlockWidth:=4;
   result.BlockHeight:=4;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK,VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK,VK_FORMAT_EAC_R11_UNORM_BLOCK,VK_FORMAT_EAC_R11_SNORM_BLOCK,VK_FORMAT_EAC_R11G11_UNORM_BLOCK,VK_FORMAT_EAC_R11G11_SNORM_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=4;
   result.BlockHeight:=4;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_4x4_UNORM_BLOCK,VK_FORMAT_ASTC_4x4_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=4;
   result.BlockHeight:=4;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_5x4_UNORM_BLOCK,VK_FORMAT_ASTC_5x4_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=5;
   result.BlockHeight:=4;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_5x5_UNORM_BLOCK,VK_FORMAT_ASTC_5x5_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=5;
   result.BlockHeight:=5;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_6x5_UNORM_BLOCK,VK_FORMAT_ASTC_6x5_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=6;
   result.BlockHeight:=5;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_6x6_UNORM_BLOCK,VK_FORMAT_ASTC_6x6_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=6;
   result.BlockHeight:=6;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_8x5_UNORM_BLOCK,VK_FORMAT_ASTC_8x5_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=8;
   result.BlockHeight:=5;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_8x6_UNORM_BLOCK,VK_FORMAT_ASTC_8x6_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=8;
   result.BlockHeight:=6;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_8x8_UNORM_BLOCK,VK_FORMAT_ASTC_8x8_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=8;
   result.BlockHeight:=8;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_10x5_UNORM_BLOCK,VK_FORMAT_ASTC_10x5_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=10;
   result.BlockHeight:=5;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_10x6_UNORM_BLOCK,VK_FORMAT_ASTC_10x6_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=10;
   result.BlockHeight:=6;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_10x8_UNORM_BLOCK,VK_FORMAT_ASTC_10x8_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=10;
   result.BlockHeight:=8;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_10x10_UNORM_BLOCK,VK_FORMAT_ASTC_10x10_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=10;
   result.BlockHeight:=10;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_12x10_UNORM_BLOCK,VK_FORMAT_ASTC_12x10_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=12;
   result.BlockHeight:=10;
   result.BlockDepth:=1;
  end;
  VK_FORMAT_ASTC_12x12_UNORM_BLOCK,VK_FORMAT_ASTC_12x12_SRGB_BLOCK:begin
   result.Flags:=[vfsfCompressed];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=16*8;
   result.BlockWidth:=12;
   result.BlockHeight:=12;
   result.BlockDepth:=1;
  end;
  else begin
   result.Flags:=[];
   result.PaletteSizeInBits:=0;
   result.BlockSizeInBits:=0*8;
   result.BlockWidth:=1;
   result.BlockHeight:=1;
   result.BlockDepth:=1;
  end;
 end;
end;

function HashData(const Data:TpvPointer;const DataLength:TpvUInt32):TpvUInt32;
const m=TpvUInt32($57559429);
      n=TpvUInt32($5052acdb);
var b:PpvUInt8;
    h,k,len:TpvUInt32;
    p:TpvUInt64;
begin
 Len:=DataLength;
 h:=len;
 k:=h+n+1;
 if len>0 then begin
  b:=Data;
  while len>7 do begin
   begin
    p:=TpvUInt32(TpvPointer(b)^)*UInt64(n);
    h:=h xor TpvUInt32(p and $ffffffff);
    k:=k xor TpvUInt32(p shr 32);
    inc(b,4);
   end;
   begin
    p:=TpvUInt32(TpvPointer(b)^)*UInt64(m);
    k:=k xor TpvUInt32(p and $ffffffff);
    h:=h xor TpvUInt32(p shr 32);
    inc(b,4);
   end;
   dec(len,8);
  end;
  if len>3 then begin
   p:=TpvUInt32(TpvPointer(b)^)*UInt64(n);
   h:=h xor TpvUInt32(p and $ffffffff);
   k:=k xor TpvUInt32(p shr 32);
   inc(b,4);
   dec(len,4);
  end;
  if len>0 then begin
   if len>1 then begin
    p:=word(TpvPointer(b)^);
    inc(b,2);
    dec(len,2);
   end else begin
    p:=0;
   end;
   if len>0 then begin
    p:=p or (TpvUInt8(b^) shl 16);
   end;
   p:=p*TpvUInt64(m);
   k:=k xor TpvUInt32(p and $ffffffff);
   h:=h xor TpvUInt32(p shr 32);
  end;
 end;
 begin
  p:=(h xor (k+n))*TpvUInt64(n);
  h:=h xor TpvUInt32(p and $ffffffff);
  k:=k xor TpvUInt32(p shr 32);
 end;
 result:=k xor h;
end;

{$ifndef HasSAR}
function SARLongint(Value,Shift:TpvInt32):TpvInt32;
{$ifdef cpu386}
{$ifdef fpc} assembler; register; //inline;
asm
 mov ecx,edx
 sar eax,cl
end;// ['eax','edx','ecx'];
{$else} assembler; register;
asm
 mov ecx,edx
 sar eax,cl
end;
{$endif}
{$else}
{$ifdef cpuarm} assembler; //inline;
asm
 mov r0,r0,asr R1
end;// ['r0','R1'];
{$else}{$ifdef CAN_INLINE}inline;{$endif}
begin
 Shift:=Shift and 31;
 result:=(TpvUInt32(Value) shr Shift) or (TpvUInt32(TpvInt32(TpvUInt32(0-TpvUInt32(TpvUInt32(Value) shr 31)) and TpvUInt32(0-TpvUInt32(ord(Shift<>0) and 1)))) shl (32-Shift));
end;
{$endif}
{$endif}
{$endif}

{$ifndef HasSAR}
function SARInt64(Value:TpvInt64;Shift:TpvInt32):TpvInt64;{$ifdef UseRegister}register;{$endif}{$ifdef CAN_INLINE}inline;{$endif}
begin
 Shift:=Shift and 63;
 result:=TpvInt64(TpvUInt64(TpvUInt64(TpvUInt64(Value) shr Shift) or (TpvUInt64(TpvInt64(TpvUInt64(0-TpvUInt64(TpvUInt64(Value) shr 63)) and TpvUInt64(TpvInt64(0-(ord(Shift<>0) and 1))))) shl (64-Shift))));
end;
{$endif}

function VulkanIntLog2(aValue:TpvUInt32):TpvUInt32;{$ifdef fpc}{$ifdef caninline}inline;{$endif}
begin
 if aValue<>0 then begin
  result:=BSRWord(aValue);
 end else begin
  result:=0;
 end;
end;
{$else}
{$ifdef cpu386}assembler; {$ifdef fpc}nostackframe;{$else}register;{$endif}
asm
 test eax,eax
 jz @Done
 bsr eax,eax
 @Done:
end;{$else}{$ifdef cpux86_64}assembler; {$ifdef fpc}nostackframe;{$else}register;{$endif}
asm
{$ifdef Windows}
 mov eax,ecx
{$else}
 mov eax,edi
{$endif}
 test eax,eax
 jz @Done
 bsr eax,eax
 @Done:
end;
{$else}
begin
 result:=aValue or (aValue shr 1);
 result:=result or (result shr 2);
 result:=result or (result shr 4);
 result:=result or (result shr 8);
 result:=result or (result shr 16);
 result:=result shr 1;
 result:=result-((result shr 1) and $55555555);
 result:=((result shr 2) and $33333333)+(result and $33333333);
 result:=((result shr 4)+result) and $0f0f0f0f;
 result:=result+(result shr 8);
 result:=result+(result shr 16);
 result:=result and $3f;
end;
{$endif}
{$endif}
{$endif}

function VulkanRoundUpToPowerOfTwo(Value:TVkSize):TVkSize;
begin
 dec(Value);
 Value:=Value or (Value shr 1);
 Value:=Value or (Value shr 2);
 Value:=Value or (Value shr 4);
 Value:=Value or (Value shr 8);
 Value:=Value or (Value shr 16);
{$ifdef CPU64}
 Value:=Value or (Value shr 32);
{$endif}
 result:=Value+1;
end;

function VulkanDeviceSizeRoundUpToPowerOfTwo(Value:TVkDeviceSize):TVkDeviceSize;
begin
 dec(Value);
 Value:=Value or (Value shr 1);
 Value:=Value or (Value shr 2);
 Value:=Value or (Value shr 4);
 Value:=Value or (Value shr 8);
 Value:=Value or (Value shr 16);
 Value:=Value or (Value shr 32);
 result:=Value+1;
end;

{$if defined(fpc)}
function CTZDWord(Value:TpvUInt32):TpvUInt8; inline;
begin
 if Value=0 then begin
  result:=32;
 end else begin
  result:=BSFDWord(Value);
 end;
end;
{$elseif defined(cpu386)}
{$ifndef fpc}
function CTZDWord(Value:TpvUInt32):TpvUInt8; assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
 bsf eax,eax
 jnz @Done
 mov eax,32
@Done:
end;
{$endif}
{$elseif defined(cpux86_64)}
{$ifndef fpc}
function CTZDWord(Value:TpvUInt32):TpvUInt8; assembler; register; {$ifdef fpc}nostackframe;{$endif}
asm
{$ifndef fpc}
 .NOFRAME
{$endif}
{$ifdef Windows}
 bsf eax,ecx
{$else}
 bsf eax,edi
{$endif}
 jnz @Done
 mov eax,32
@Done:
end;
{$endif}
{$elseif not defined(fpc)}
function CTZDWord(Value:TpvUInt32):TpvUInt8;
const CTZDebruijn32Multiplicator=TpvUInt32($077cb531);
      CTZDebruijn32Shift=27;
      CTZDebruijn32Mask=31;
      CTZDebruijn32Table:array[0..31] of TpvUInt8=(0,1,28,2,29,14,24,3,30,22,20,15,25,17,4,8,31,27,13,23,21,19,16,7,26,12,18,6,11,5,10,9);
begin
 if Value=0 then begin
  result:=32;
 end else begin
  result:=CTZDebruijn32Table[((TpvUInt32(Value and (-Value))*CTZDebruijn32Multiplicator) shr CTZDebruijn32Shift) and CTZDebruijn32Mask];
 end;
end;
{$ifend}

function HashString(const Str:TpvRawByteString):TpvUInt32;
{$ifdef cpuarm}
var b:PpvVulkanRawByteChar;
    len,h,i:TpvUInt32;
begin
 result:=2166136261;
 len:=length(Str);
 h:=len;
 if len>0 then begin
  b:=PpvVulkanRawByteChar(Str);
  while len>3 do begin
   i:=TpvUInt32(TpvPointer(b)^);
   h:=(h xor i) xor $2e63823a;
   inc(h,(h shl 15) or (h shr (32-15)));
   dec(h,(h shl 9) or (h shr (32-9)));
   inc(h,(h shl 4) or (h shr (32-4)));
   dec(h,(h shl 1) or (h shr (32-1)));
   h:=h xor (h shl 2) or (h shr (32-2));
   result:=result xor i;
   inc(result,(result shl 1)+(result shl 4)+(result shl 7)+(result shl 8)+(result shl 24));
   inc(b,4);
   dec(len,4);
  end;
  if len>1 then begin
   i:=word(TpvPointer(b)^);
   h:=(h xor i) xor $2e63823a;
   inc(h,(h shl 15) or (h shr (32-15)));
   dec(h,(h shl 9) or (h shr (32-9)));
   inc(h,(h shl 4) or (h shr (32-4)));
   dec(h,(h shl 1) or (h shr (32-1)));
   h:=h xor (h shl 2) or (h shr (32-2));
   result:=result xor i;
   inc(result,(result shl 1)+(result shl 4)+(result shl 7)+(result shl 8)+(result shl 24));
   inc(b,2);
   dec(len,2);
  end;
  if len>0 then begin
   i:=TpvUInt8(b^);
   h:=(h xor i) xor $2e63823a;
   inc(h,(h shl 15) or (h shr (32-15)));
   dec(h,(h shl 9) or (h shr (32-9)));
   inc(h,(h shl 4) or (h shr (32-4)));
   dec(h,(h shl 1) or (h shr (32-1)));
   h:=h xor (h shl 2) or (h shr (32-2));
   result:=result xor i;
   inc(result,(result shl 1)+(result shl 4)+(result shl 7)+(result shl 8)+(result shl 24));
  end;
 end;
 result:=result xor h;
 if result=0 then begin
  result:=$ffffffff;
 end;
end;
{$else}
const m=TpvUInt32($57559429);
      n=TpvUInt32($5052acdb);
var b:PpvVulkanRawByteChar;
    h,k,len:TpvUInt32;
    p:TpvUInt64;
begin
 len:=length(Str);
 h:=len;
 k:=h+n+1;
 if len>0 then begin
  b:=PpvVulkanRawByteChar(Str);
  while len>7 do begin
   begin
    p:=TpvUInt32(TpvPointer(b)^)*TpvUInt64(n);
    h:=h xor TpvUInt32(p and $ffffffff);
    k:=k xor TpvUInt32(p shr 32);
    inc(b,4);
   end;
   begin
    p:=TpvUInt32(TpvPointer(b)^)*TpvUInt64(m);
    k:=k xor TpvUInt32(p and $ffffffff);
    h:=h xor TpvUInt32(p shr 32);
    inc(b,4);
   end;
   dec(len,8);
  end;
  if len>3 then begin
   p:=TpvUInt32(TpvPointer(b)^)*TpvUInt64(n);
   h:=h xor TpvUInt32(p and $ffffffff);
   k:=k xor TpvUInt32(p shr 32);
   inc(b,4);
   dec(len,4);
  end;
  if len>0 then begin
   if len>1 then begin
    p:=word(TpvPointer(b)^);
    inc(b,2);
    dec(len,2);
   end else begin
    p:=0;
   end;
   if len>0 then begin
    p:=p or (TpvUInt8(b^) shl 16);
   end;
   p:=p*TpvUInt64(m);
   k:=k xor TpvUInt32(p and $ffffffff);
   h:=h xor TpvUInt32(p shr 32);
  end;
 end;
 begin
  p:=(h xor (k+n))*TpvUInt64(n);
  h:=h xor TpvUInt32(p and $ffffffff);
  k:=k xor TpvUInt32(p shr 32);
 end;
 result:=k xor h;
 if result=0 then begin
  result:=$ffffffff;
 end;
end;
{$endif}

function HashPointer(const p:TpvPointer):TpvUInt32; {$ifdef caninline}inline;{$endif}
{$ifdef cpu64}
var r:TpvPtrUInt;
begin
 r:=TpvPtrUInt(p);
 r:=(not r)+(r shl 18); // r:=((r shl 18)-r-)1;
 r:=r xor (r shr 31);
 r:=r*21; // r:=(r+(r shl 2))+(r shl 4);
 r:=r xor (r shr 11);
 r:=r+(r shl 6);
 result:=TpvUInt32(TpvPtrUInt(r xor (r shr 22)));
 if result=0 then begin
  result:=$ffffffff;
 end;
end;
{$else}
begin
 result:=TpvPtrUInt(p);
 result:=(not result)+(result shl 15);
 result:=result xor (result shr 15);
 inc(result,result shl 2);
 result:=(result xor (result shr 4))*2057;
 result:=result xor (result shr 16);
 if result=0 then begin
  result:=$ffffffff;
 end;
end;
{$endif}

function HashUInt32(const p:TpvUInt32):TpvUInt32; {$ifdef caninline}inline;{$endif}
begin
 result:=TpvUInt32(p);
 result:=(not result)+(result shl 15);
 result:=result xor (result shr 15);
 inc(result,result shl 2);
 result:=(result xor (result shr 4))*2057;
 result:=result xor (result shr 16);
 if result=0 then begin
  result:=$ffffffff;
 end;
end;

function HashUInt64(const p:TpvUInt64):TpvUInt32; {$ifdef caninline}inline;{$endif}
var r:TpvUInt64;
begin
 r:=TpvUInt64(p);
 r:=(not r)+(r shl 18); // r:=((r shl 18)-r-)1;
 r:=r xor (r shr 31);
 r:=r*21; // r:=(r+(r shl 2))+(r shl 4);
 r:=r xor (r shr 11);
 r:=r+(r shl 6);
 result:=TpvUInt32(TpvUInt64(r xor (r shr 22)));
 if result=0 then begin
  result:=$ffffffff;
 end;
end;

function VulkanErrorToString(const ErrorCode:TVkResult):TpvVulkanCharString;
begin
 case ErrorCode of
  VK_SUCCESS:begin
   result:='VK_SUCCESS';
  end;
  VK_NOT_READY:begin
   result:='VK_NOT_READY';
  end;
  VK_TIMEOUT:begin
   result:='VK_TIMEOUT';
  end;
  VK_EVENT_SET:begin
   result:='VK_EVENT_SET';
  end;
  VK_EVENT_RESET:begin
   result:='VK_EVENT_RESET';
  end;
  VK_INCOMPLETE:begin
   result:='VK_INCOMPLETE';
  end;
  VK_ERROR_OUT_OF_HOST_MEMORY:begin
   result:='VK_ERROR_OUT_OF_HOST_MEMORY';
  end;
  VK_ERROR_OUT_OF_DEVICE_MEMORY:begin
   result:='VK_ERROR_OUT_OF_DEVICE_MEMORY';
  end;
  VK_ERROR_INITIALIZATION_FAILED:begin
   result:='VK_ERROR_INITIALIZATION_FAILED';
  end;
  VK_ERROR_DEVICE_LOST:begin
   result:='VK_ERROR_DEVICE_LOST';
  end;
  VK_ERROR_MEMORY_MAP_FAILED:begin
   result:='VK_ERROR_MEMORY_MAP_FAILED';
  end;
  VK_ERROR_LAYER_NOT_PRESENT:begin
   result:='VK_ERROR_LAYER_NOT_PRESENT';
  end;
  VK_ERROR_EXTENSION_NOT_PRESENT:begin
   result:='VK_ERROR_EXTENSION_NOT_PRESENT';
  end;
  VK_ERROR_FEATURE_NOT_PRESENT:begin
   result:='VK_ERROR_FEATURE_NOT_PRESENT';
  end;
  VK_ERROR_INCOMPATIBLE_DRIVER:begin
   result:='VK_ERROR_INCOMPATIBLE_DRIVER';
  end;
  VK_ERROR_TOO_MANY_OBJECTS:begin
   result:='VK_ERROR_TOO_MANY_OBJECTS';
  end;
  VK_ERROR_FORMAT_NOT_SUPPORTED:begin
   result:='VK_ERROR_FORMAT_NOT_SUPPORTED';
  end;
  VK_ERROR_SURFACE_LOST_KHR:begin
   result:='VK_ERROR_SURFACE_LOST_KHR';
  end;
  VK_ERROR_NATIVE_WINDOW_IN_USE_KHR:begin
   result:='VK_ERROR_NATIVE_WINDOW_IN_USE_KHR';
  end;
  VK_SUBOPTIMAL_KHR:begin
   result:='VK_SUBOPTIMAL_KHR';
  end;
  VK_ERROR_OUT_OF_DATE_KHR:begin
   result:='VK_ERROR_OUT_OF_DATE_KHR';
  end;
  VK_ERROR_INCOMPATIBLE_DISPLAY_KHR:begin
   result:='VK_ERROR_INCOMPATIBLE_DISPLAY_KHR';
  end;
  VK_ERROR_VALIDATION_FAILED_EXT:begin
   result:='VK_ERROR_VALIDATION_FAILED_EXT';
  end;
  VK_ERROR_INVALID_SHADER_NV:begin
   result:='VK_ERROR_INVALID_SHADER_NV';
  end;
  else begin
   result:='Unknown error code detected ('+TpvVulkanCharString(IntToStr(TpvInt32(ErrorCode)))+')';
  end;
 end;
end;

function StringListToVulkanCharStringArray(const StringList:TStringList):TpvVulkanCharStringArray;
var i:TpvInt32;
begin
 result:=nil;
 SetLength(result,StringList.Count);
 for i:=0 to StringList.Count-1 do begin
  result[i]:=TpvVulkanCharString(StringList.Strings[i]);
 end;
end;

procedure HandleResultCode(const ResultCode:TVkResult);
begin
 if ResultCode<>VK_SUCCESS then begin
  raise EpvVulkanResultException.Create(ResultCode);
 end;
end;

procedure VulkanSetImageLayout(const aImage:TVkImage;
                               const aAspectMask:TVkImageAspectFlags;
                               const aOldImageLayout:TVkImageLayout;
                               const aNewImageLayout:TVkImageLayout;
                               const aRange:PVkImageSubresourceRange;
                               const aCommandBuffer:TpvVulkanCommandBuffer;
                               const aQueue:TpvVulkanQueue=nil;
                               const aFence:TpvVulkanFence=nil;
                               const aBeginAndExecuteCommandBuffer:boolean=false;
                               const aSrcQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED);
                               const aDstQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED));
var ImageMemoryBarrier:TVkImageMemoryBarrier;
    SrcStages,DestStages:TVkPipelineStageFlags;
begin

 if aBeginAndExecuteCommandBuffer then begin
  aCommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
  aCommandBuffer.BeginRecording;
 end;

 FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
 ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
 ImageMemoryBarrier.oldLayout:=aOldImageLayout;
 ImageMemoryBarrier.newLayout:=aNewImageLayout;
 ImageMemoryBarrier.srcQueueFamilyIndex:=aSrcQueueFamilyIndex;
 ImageMemoryBarrier.dstQueueFamilyIndex:=aDstQueueFamilyIndex;
 ImageMemoryBarrier.image:=aImage;

 if assigned(aRange) then begin
  ImageMemoryBarrier.subresourceRange:=aRange^;
 end else begin
  ImageMemoryBarrier.subresourceRange.aspectMask:=aAspectMask;
  ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
  ImageMemoryBarrier.subresourceRange.levelCount:=1;
  ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
  ImageMemoryBarrier.subresourceRange.layerCount:=1;
 end;

 case aOldImageLayout of
  VK_IMAGE_LAYOUT_UNDEFINED:begin
   ImageMemoryBarrier.srcAccessMask:=0; //TVkAccessFlags(VK_ACCESS_HOST_WRITE_BIT) or TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_GENERAL:begin
  end;
  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL:begin
  end;
  VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
  end;
  VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
  end;
  VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_PREINITIALIZED:begin
   ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_HOST_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_PRESENT_SRC_KHR:begin
  end;
 end;

 case aNewImageLayout of
  VK_IMAGE_LAYOUT_UNDEFINED:begin
  end;
  VK_IMAGE_LAYOUT_GENERAL:begin
   if aOldImageLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL then begin
    ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
   end;
  end;
  VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL:begin
   if aOldImageLayout=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR then begin
    ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT);
   end;
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL:begin
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL:begin
  end;
  VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL:begin
   if aOldImageLayout=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL then begin
    ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
   end;
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT) or TVkAccessFlags(VK_ACCESS_INPUT_ATTACHMENT_READ_BIT);
  end;
  VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL:begin
   ImageMemoryBarrier.srcAccessMask:=ImageMemoryBarrier.srcAccessMask or TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
  end;
  VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL:begin
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
  end;
  VK_IMAGE_LAYOUT_PREINITIALIZED:begin
  end;
  VK_IMAGE_LAYOUT_PRESENT_SRC_KHR:begin
   if aOldImageLayout=VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL then begin
    ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
   end;
   ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT);
  end;
 end;

 if aOldImageLayout=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR then begin
  SrcStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
  DestStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
 end else if aNewImageLayout=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR then begin
  SrcStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT);
  DestStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT);
 end else begin
  SrcStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
  DestStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT);
 end;

 aCommandBuffer.CmdPipelineBarrier(SrcStages,DestStages,0,0,nil,0,nil,1,@ImageMemoryBarrier);

 if aBeginAndExecuteCommandBuffer then begin
  aCommandBuffer.EndRecording;
  aCommandBuffer.Execute(aQueue,TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),nil,nil,aFence,true);
 end;

end;

procedure VulkanDisableFloatingPointExceptions;
begin
{$if declared(SetExceptionMask)}
 SetExceptionMask([exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);
{$ifend}
end;

constructor EpvVulkanResultException.Create(const aResultCode:TVkResult);
begin
 fResultCode:=aResultCode;
 inherited Create(String(VulkanErrorToString(fResultCode)));
end;

destructor EpvVulkanResultException.Destroy;
begin
 inherited Destroy;
end;

constructor TpvVulkanBaseList.Create(const aItemSize:TVkSizeInt);
begin
 inherited Create;
 fItemSize:=aItemSize;
 fCount:=0;
 fAllocated:=0;
 fMemory:=nil;
end;

destructor TpvVulkanBaseList.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TpvVulkanBaseList.SetCount(const NewCount:TVkSizeInt);
var Index,NewAllocated:TVkSizeInt;
    Item:TpvPointer;
begin
 if fCount<NewCount then begin
  NewAllocated:=TVkSizeInt(VulkanRoundUpToPowerOfTwo(NewCount));
  if fAllocated<NewAllocated then begin
   if assigned(fMemory) then begin
    ReallocMem(fMemory,NewAllocated*fItemSize);
   end else begin
    GetMem(fMemory,NewAllocated*fItemSize);
   end;
   FillChar(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(fAllocated)*TpvPtrUInt(fItemSize))))^,(NewAllocated-fAllocated)*fItemSize,#0);
   fAllocated:=NewAllocated;
  end;
  Item:=fMemory;
  Index:=fCount;
  inc(TpvPtrUInt(Item),Index*fItemSize);
  while Index<NewCount do begin
   FillChar(Item^,fItemSize,#0);
   InitializeItem(Item^);
   inc(TpvPtrUInt(Item),fItemSize);
   inc(Index);
  end;
  fCount:=NewCount;
 end else if fCount>NewCount then begin
  Item:=fMemory;
  Index:=NewCount;
  inc(TpvPtrUInt(Item),Index*fItemSize);
  while Index<fCount do begin
   FinalizeItem(Item^);
   FillChar(Item^,fItemSize,#0);
   inc(TpvPtrUInt(Item),fItemSize);
   inc(Index);
  end;
  fCount:=NewCount;
  if NewCount<(fAllocated shr 2) then begin
   if NewCount=0 then begin
    if assigned(fMemory) then begin
     FreeMem(fMemory);
     fMemory:=nil;
    end;
    fAllocated:=0;
   end else begin                             
    NewAllocated:=fAllocated shr 1;
    if assigned(fMemory) then begin
     ReallocMem(fMemory,NewAllocated*fItemSize);
    end else begin
     GetMem(fMemory,NewAllocated*fItemSize);
    end;
    fAllocated:=NewAllocated;
   end;
  end;
 end;
end;

function TpvVulkanBaseList.GetItem(const Index:TVkSizeInt):TpvPointer;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))));
 end else begin
  result:=nil;
 end;
end;

procedure TpvVulkanBaseList.InitializeItem(var Item);
begin
end;

procedure TpvVulkanBaseList.FinalizeItem(var Item);
begin
end;

procedure TpvVulkanBaseList.CopyItem(const Source;var Destination);
begin
 Move(Source,Destination,fItemSize);
end;

procedure TpvVulkanBaseList.ExchangeItem(var Source,Destination);
var a,b:PpvUInt8;
    c8:TpvUInt8;
    c32:TpvUInt32;
    Index:TpvInt32;
begin
 a:=@Source;
 b:=@Destination;
 for Index:=1 to fItemSize shr 2 do begin
  c32:=PpvUInt32(a)^;
  PpvUInt32(a)^:=PpvUInt32(b)^;
  PpvUInt32(b)^:=c32;
  inc(PpvUInt32(a));
  inc(PpvUInt32(b));
 end;
 for Index:=1 to fItemSize and 3 do begin
  c8:=a^;
  a^:=b^;
  b^:=c8;
  inc(a);
  inc(b);
 end;
end;

function TpvVulkanBaseList.CompareItem(const Source,Destination):TpvInt32;
var a,b:PpvUInt8;
    Index:TpvInt32;
begin
 result:=0;
 a:=@Source;
 b:=@Destination;
 for Index:=1 to fItemSize do begin
  result:=a^-b^;
  if result<>0 then begin
   exit;
  end;
  inc(a);
  inc(b);
 end;
end;

procedure TpvVulkanBaseList.Clear;
var Index:TVkSizeInt;
    Item:TpvPointer;
begin
 Item:=fMemory;
 Index:=0;
 while Index<fCount do begin
  FinalizeItem(Item^);
  inc(TpvPtrInt(Item),fItemSize);
  inc(Index);
 end;
 if assigned(fMemory) then begin
  FreeMem(fMemory);
  fMemory:=nil;
 end;
 fCount:=0;
 fAllocated:=0;
end;

procedure TpvVulkanBaseList.FillWith(const SourceData;const SourceCount:TVkSizeInt);
var Index:TVkSizeInt;
    SourceItem,Item:TpvPointer;
begin
 SourceItem:=@SourceData;
 if assigned(SourceItem) and (SourceCount>0) then begin
  SetCount(SourceCount);
  Item:=fMemory;
  Index:=0;
  while Index<fCount do begin
   CopyItem(SourceItem^,Item^);
   inc(TpvPtrInt(SourceItem),fItemSize);
   inc(TpvPtrInt(Item),fItemSize);
   inc(Index);
  end;
 end else begin
  SetCount(0);
 end;
end;

function TpvVulkanBaseList.Add(const Item):TVkSizeInt;
begin
 result:=fCount;
 SetCount(result+1);
 CopyItem(Item,TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(result)*TpvPtrUInt(fItemSize))))^);
end;

function TpvVulkanBaseList.Find(const Item):TVkSizeInt;
var Index:TVkSizeInt;
begin
 result:=-1;
 Index:=0;
 while Index<fCount do begin
  if CompareItem(Item,TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^)=0 then begin
   result:=Index;
   break;
  end;
  inc(Index);
 end;
end;

procedure TpvVulkanBaseList.Insert(const Index:TVkSizeInt;const Item);
begin
 if Index>=0 then begin
  if Index<fCount then begin
   SetCount(fCount+1);
   Move(TpvPointer(TpvPtrInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^,TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index+1)*TpvPtrUInt(fItemSize))))^,(fCount-Index)*fItemSize);
   FillChar(TpvPointer(TpvPtrInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^,fItemSize,#0);
  end else begin
   SetCount(Index+1);
  end;
  CopyItem(Item,TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end;
end;

procedure TpvVulkanBaseList.Delete(const Index:TVkSizeInt);
begin
 if (Index>=0) and (Index<fCount) then begin
  FinalizeItem(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
  Move(TpvPointer(TpvPtrUInt(TpvPtruInt(fMemory)+(TpvPtrUInt(Index+1)*TpvPtrUInt(fItemSize))))^,TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^,(fCount-Index)*fItemSize);
  FillChar(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(fCount-1)*TpvPtrUInt(fItemSize))))^,fItemSize,#0);
  SetCount(fCount-1);
 end;
end;

procedure TpvVulkanBaseList.Remove(const Item);
var Index:TVkSizeInt;
begin
 repeat
  Index:=Find(Item);
  if Index>=0 then begin
   Delete(Index);
  end else begin
   break;
  end;
 until false;
end;

procedure TpvVulkanBaseList.Exchange(const Index,WithIndex:TVkSizeInt);
begin
 if (Index>=0) and (Index<fCount) and (WithIndex>=0) and (WithIndex<fCount) then begin
  ExchangeItem(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^,TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(WithIndex)*TpvPtrUInt(fItemSize))))^);
 end;
end;

constructor TpvVulkanObjectList.Create;
begin
 fOwnObjects:=true;
 inherited Create(SizeOf(TpvVulkanObject));
end;

destructor TpvVulkanObjectList.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanObjectList.Clear;
begin
 inherited Clear;
end;

function TpvVulkanObjectList.GetItem(const Index:TVkSizeInt):TpvVulkanObject;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TpvVulkanObject(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=nil;
 end;
end;

procedure TpvVulkanObjectList.SetItem(const Index:TVkSizeInt;const Item:TpvVulkanObject);
begin
 if (Index>=0) and (Index<fCount) then begin
  TpvVulkanObject(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TpvVulkanObjectList.InitializeItem(var Item);
begin
 TpvVulkanObject(TpvPointer(Item)):=nil;
end;

procedure TpvVulkanObjectList.FinalizeItem(var Item);
begin
 if fOwnObjects then begin
  TpvVulkanObject(TpvPointer(Item)).Free;
 end;
 TpvVulkanObject(TpvPointer(Item)):=nil;
end;

procedure TpvVulkanObjectList.CopyItem(const Source;var Destination);
begin
 TpvVulkanObject(TpvPointer(Destination)):=TpvVulkanObject(TpvPointer(Source));
end;

procedure TpvVulkanObjectList.ExchangeItem(var Source,Destination);
var Temporary:TpvVulkanObject;
begin
 Temporary:=TpvVulkanObject(TpvPointer(Source));
 TpvVulkanObject(TpvPointer(Source)):=TpvVulkanObject(TpvPointer(Destination));
 TpvVulkanObject(TpvPointer(Destination)):=Temporary;
end;

function TpvVulkanObjectList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TpvPtrDiff(Source)-TpvPtrDiff(Destination);
end;

function TpvVulkanObjectList.Add(const Item:TpvVulkanObject):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TpvVulkanObjectList.Find(const Item:TpvVulkanObject):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TpvVulkanObjectList.Insert(const Index:TVkSizeInt;const Item:TpvVulkanObject);
begin
 inherited Insert(Index,Item);
end;

procedure TpvVulkanObjectList.Remove(const Item:TpvVulkanObject);
begin
 inherited Remove(Item);
end;

constructor TVkUInt32List.Create;
begin
 inherited Create(SizeOf(TpvUInt32));
end;

destructor TVkUInt32List.Destroy;
begin
 inherited Destroy;
end;

function TVkUInt32List.GetItem(const Index:TVkSizeInt):TpvUInt32;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TpvUInt32(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkUInt32List.SetItem(const Index:TVkSizeInt;const Item:TpvUInt32);
begin
 if (Index>=0) and (Index<fCount) then begin
  TpvUInt32(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkUInt32List.InitializeItem(var Item);
begin
 TpvUInt32(Item):=0;
end;

procedure TVkUInt32List.FinalizeItem(var Item);
begin
 TpvUInt32(Item):=0;
end;

procedure TVkUInt32List.CopyItem(const Source;var Destination);
begin
 TpvUInt32(Destination):=TpvUInt32(Source);
end;

procedure TVkUInt32List.ExchangeItem(var Source,Destination);
var Temporary:TpvUInt32;
begin
 Temporary:=TpvUInt32(Source);
 TpvUInt32(Source):=TpvUInt32(Destination);
 TpvUInt32(Destination):=Temporary;
end;

function TVkUInt32List.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TpvUInt32(Source)-TpvUInt32(Destination);
end;

function TVkUInt32List.Add(const Item:TpvUInt32):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkUInt32List.Find(const Item:TpvUInt32):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkUInt32List.Insert(const Index:TVkSizeInt;const Item:TpvUInt32);
begin
 inherited Insert(Index,Item);
end;

procedure TVkUInt32List.Remove(const Item:TpvUInt32);
begin
 inherited Remove(Item);
end;

constructor TVkFloatList.Create;
begin
 inherited Create(SizeOf(TpvFloat));
end;

destructor TVkFloatList.Destroy;
begin
 inherited Destroy;
end;

function TVkFloatList.GetItem(const Index:TVkSizeInt):TpvFloat;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TpvFloat(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkFloatList.SetItem(const Index:TVkSizeInt;const Item:TpvFloat);
begin
 if (Index>=0) and (Index<fCount) then begin
  TpvFloat(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkFloatList.InitializeItem(var Item);
begin
 TpvFloat(Item):=0;
end;

procedure TVkFloatList.FinalizeItem(var Item);
begin
 TpvFloat(Item):=0;
end;

procedure TVkFloatList.CopyItem(const Source;var Destination);
begin
 TpvFloat(Destination):=TpvFloat(Source);
end;

procedure TVkFloatList.ExchangeItem(var Source,Destination);
var Temporary:TpvFloat;
begin
 Temporary:=TpvFloat(Source);
 TpvFloat(Source):=TpvFloat(Destination);
 TpvFloat(Destination):=Temporary;
end;

function TVkFloatList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TpvInt32(Source)-TpvInt32(Destination);
end;

function TVkFloatList.Add(const Item:TpvFloat):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkFloatList.Find(const Item:TpvFloat):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkFloatList.Insert(const Index:TVkSizeInt;const Item:TpvFloat);
begin
 inherited Insert(Index,Item);
end;

procedure TVkFloatList.Remove(const Item:TpvFloat);
begin
 inherited Remove(Item);
end;

constructor TVkImageViewList.Create;
begin
 inherited Create(SizeOf(TVkImageView));
end;

destructor TVkImageViewList.Destroy;
begin
 inherited Destroy;
end;

function TVkImageViewList.GetItem(const Index:TVkSizeInt):TVkImageView;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkImageView(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkImageViewList.SetItem(const Index:TVkSizeInt;const Item:TVkImageView);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkImageView(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkImageViewList.InitializeItem(var Item);
begin
 TVkImageView(Item):=0;
end;

procedure TVkImageViewList.FinalizeItem(var Item);
begin
 TVkImageView(Item):=0;
end;

procedure TVkImageViewList.CopyItem(const Source;var Destination);
begin
 TVkImageView(Destination):=TVkImageView(Source);
end;

procedure TVkImageViewList.ExchangeItem(var Source,Destination);
var Temporary:TVkImageView;
begin
 Temporary:=TVkImageView(Source);
 TVkImageView(Source):=TVkImageView(Destination);
 TVkImageView(Destination):=Temporary;
end;

function TVkImageViewList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TVkImageView(Source)-TVkImageView(Destination);
end;

function TVkImageViewList.Add(const Item:TVkImageView):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkImageViewList.Find(const Item:TVkImageView):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkImageViewList.Insert(const Index:TVkSizeInt;const Item:TVkImageView);
begin
 inherited Insert(Index,Item);
end;

procedure TVkImageViewList.Remove(const Item:TVkImageView);
begin
 inherited Remove(Item);
end;

constructor TVkSamplerList.Create;
begin
 inherited Create(SizeOf(TVkSampler));
end;

destructor TVkSamplerList.Destroy;
begin
 inherited Destroy;
end;

function TVkSamplerList.GetItem(const Index:TVkSizeInt):TVkSampler;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkSampler(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkSamplerList.SetItem(const Index:TVkSizeInt;const Item:TVkSampler);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkSampler(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkSamplerList.InitializeItem(var Item);
begin
 TVkSampler(Item):=0;
end;

procedure TVkSamplerList.FinalizeItem(var Item);
begin
 TVkSampler(Item):=0;
end;

procedure TVkSamplerList.CopyItem(const Source;var Destination);
begin
 TVkSampler(Destination):=TVkSampler(Source);
end;

procedure TVkSamplerList.ExchangeItem(var Source,Destination);
var Temporary:TVkSampler;
begin
 Temporary:=TVkSampler(Source);
 TVkSampler(Source):=TVkSampler(Destination);
 TVkSampler(Destination):=Temporary;
end;

function TVkSamplerList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TVkSampler(Source)-TVkSampler(Destination);
end;

function TVkSamplerList.Add(const Item:TVkSampler):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkSamplerList.Find(const Item:TVkSampler):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkSamplerList.Insert(const Index:TVkSizeInt;const Item:TVkSampler);
begin
 inherited Insert(Index,Item);
end;

procedure TVkSamplerList.Remove(const Item:TVkSampler);
begin
 inherited Remove(Item);
end;

constructor TVkDescriptorSetLayoutList.Create;
begin
 inherited Create(SizeOf(TVkDescriptorSetLayout));
end;

destructor TVkDescriptorSetLayoutList.Destroy;
begin
 inherited Destroy;
end;

function TVkDescriptorSetLayoutList.GetItem(const Index:TVkSizeInt):TVkDescriptorSetLayout;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkDescriptorSetLayout(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkDescriptorSetLayoutList.SetItem(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkDescriptorSetLayout(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkDescriptorSetLayoutList.InitializeItem(var Item);
begin
 TVkDescriptorSetLayout(Item):=0;
end;

procedure TVkDescriptorSetLayoutList.FinalizeItem(var Item);
begin
 TVkDescriptorSetLayout(Item):=0;
end;

procedure TVkDescriptorSetLayoutList.CopyItem(const Source;var Destination);
begin
 TVkDescriptorSetLayout(Destination):=TVkDescriptorSetLayout(Source);
end;

procedure TVkDescriptorSetLayoutList.ExchangeItem(var Source,Destination);
var Temporary:TVkDescriptorSetLayout;
begin
 Temporary:=TVkDescriptorSetLayout(Source);
 TVkDescriptorSetLayout(Source):=TVkDescriptorSetLayout(Destination);
 TVkDescriptorSetLayout(Destination):=Temporary;
end;

function TVkDescriptorSetLayoutList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TVkDescriptorSetLayout(Source)-TVkDescriptorSetLayout(Destination);
end;

function TVkDescriptorSetLayoutList.Add(const Item:TVkDescriptorSetLayout):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkDescriptorSetLayoutList.Find(const Item:TVkDescriptorSetLayout):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkDescriptorSetLayoutList.Insert(const Index:TVkSizeInt;const Item:TVkDescriptorSetLayout);
begin
 inherited Insert(Index,Item);
end;

procedure TVkDescriptorSetLayoutList.Remove(const Item:TVkDescriptorSetLayout);
begin
 inherited Remove(Item);
end;

constructor TVkSampleMaskList.Create;
begin
 inherited Create(SizeOf(TVkSampleMask));
end;

destructor TVkSampleMaskList.Destroy;
begin
 inherited Destroy;
end;

function TVkSampleMaskList.GetItem(const Index:TVkSizeInt):TVkSampleMask;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkSampleMask(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=0;
 end;
end;

procedure TVkSampleMaskList.SetItem(const Index:TVkSizeInt;const Item:TVkSampleMask);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkSampleMask(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkSampleMaskList.InitializeItem(var Item);
begin
 TVkSampleMask(Item):=0;
end;

procedure TVkSampleMaskList.FinalizeItem(var Item);
begin
 TVkSampleMask(Item):=0;
end;

procedure TVkSampleMaskList.CopyItem(const Source;var Destination);
begin
 TVkSampleMask(Destination):=TVkSampleMask(Source);
end;

procedure TVkSampleMaskList.ExchangeItem(var Source,Destination);
var Temporary:TVkSampleMask;
begin
 Temporary:=TVkSampleMask(Source);
 TVkSampleMask(Source):=TVkSampleMask(Destination);
 TVkSampleMask(Destination):=Temporary;
end;

function TVkSampleMaskList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TVkSampleMask(Source)-TVkSampleMask(Destination);
end;

function TVkSampleMaskList.Add(const Item:TVkSampleMask):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkSampleMaskList.Find(const Item:TVkSampleMask):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkSampleMaskList.Insert(const Index:TVkSizeInt;const Item:TVkSampleMask);
begin
 inherited Insert(Index,Item);
end;

procedure TVkSampleMaskList.Remove(const Item:TVkSampleMask);
begin
 inherited Remove(Item);
end;

constructor TVkDynamicStateList.Create;
begin
 inherited Create(SizeOf(TVkDynamicState));
end;

destructor TVkDynamicStateList.Destroy;
begin
 inherited Destroy;
end;

function TVkDynamicStateList.GetItem(const Index:TVkSizeInt):TVkDynamicState;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkDynamicState(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=TVkDynamicState(0);
 end;
end;

procedure TVkDynamicStateList.SetItem(const Index:TVkSizeInt;const Item:TVkDynamicState);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkDynamicState(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkDynamicStateList.InitializeItem(var Item);
begin
 Initialize(TVkDynamicState(Item));
end;

procedure TVkDynamicStateList.FinalizeItem(var Item);
begin
 Finalize(TVkDynamicState(Item));
end;

procedure TVkDynamicStateList.CopyItem(const Source;var Destination);
begin
 TVkDynamicState(Destination):=TVkDynamicState(Source);
end;

procedure TVkDynamicStateList.ExchangeItem(var Source,Destination);
var Temporary:TVkDynamicState;
begin
 Temporary:=TVkDynamicState(Source);
 TVkDynamicState(Source):=TVkDynamicState(Destination);
 TVkDynamicState(Destination):=Temporary;
end;

function TVkDynamicStateList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TVkSize(TVkDynamicState(Source))-TVkSize(TVkDynamicState(Destination));
end;

function TVkDynamicStateList.Add(const Item:TVkDynamicState):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkDynamicStateList.Find(const Item:TVkDynamicState):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkDynamicStateList.Insert(const Index:TVkSizeInt;const Item:TVkDynamicState);
begin
 inherited Insert(Index,Item);
end;

procedure TVkDynamicStateList.Remove(const Item:TVkDynamicState);
begin
 inherited Remove(Item);
end;

constructor TVkBufferViewList.Create;
begin
 inherited Create(SizeOf(TVkBufferView));
end;

destructor TVkBufferViewList.Destroy;
begin
 inherited Destroy;
end;

function TVkBufferViewList.GetItem(const Index:TVkSizeInt):TVkBufferView;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkBufferView(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  result:=TVkBufferView(0);
 end;
end;

procedure TVkBufferViewList.SetItem(const Index:TVkSizeInt;const Item:TVkBufferView);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkBufferView(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkBufferViewList.InitializeItem(var Item);
begin
 Initialize(TVkBufferView(Item));
end;

procedure TVkBufferViewList.FinalizeItem(var Item);
begin
 Finalize(TVkBufferView(Item));
end;

procedure TVkBufferViewList.CopyItem(const Source;var Destination);
begin
 TVkBufferView(Destination):=TVkBufferView(Source);
end;

procedure TVkBufferViewList.ExchangeItem(var Source,Destination);
var Temporary:TVkBufferView;
begin
 Temporary:=TVkBufferView(Source);
 TVkBufferView(Source):=TVkBufferView(Destination);
 TVkBufferView(Destination):=Temporary;
end;

function TVkBufferViewList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=TVkSize(TVkBufferView(Source))-TVkSize(TVkBufferView(Destination));
end;

function TVkBufferViewList.Add(const Item:TVkBufferView):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkBufferViewList.Find(const Item:TVkBufferView):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkBufferViewList.Insert(const Index:TVkSizeInt;const Item:TVkBufferView);
begin
 inherited Insert(Index,Item);
end;

procedure TVkBufferViewList.Remove(const Item:TVkBufferView);
begin
 inherited Remove(Item);
end;

constructor TVkClearValueList.Create;
begin
 inherited Create(SizeOf(TVkClearValue));
end;

destructor TVkClearValueList.Destroy;
begin
 inherited Destroy;
end;

function TVkClearValueList.GetItem(const Index:TVkSizeInt):TVkClearValue;
begin
 if (Index>=0) and (Index<fCount) then begin
  result:=TVkClearValue(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^);
 end else begin
  FillChar(result,SizeOf(TVkClearValue),#0);
 end;
end;

procedure TVkClearValueList.SetItem(const Index:TVkSizeInt;const Item:TVkClearValue);
begin
 if (Index>=0) and (Index<fCount) then begin
  TVkClearValue(TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+(TpvPtrUInt(Index)*TpvPtrUInt(fItemSize))))^):=Item;
 end;
end;

procedure TVkClearValueList.InitializeItem(var Item);
begin
 Initialize(TVkClearValue(Item));
end;

procedure TVkClearValueList.FinalizeItem(var Item);
begin
 Finalize(TVkClearValue(Item));
end;

procedure TVkClearValueList.CopyItem(const Source;var Destination);
begin
 TVkClearValue(Destination):=TVkClearValue(Source);
end;

procedure TVkClearValueList.ExchangeItem(var Source,Destination);
var Temporary:TVkClearValue;
begin
 Temporary:=TVkClearValue(Source);
 TVkClearValue(Source):=TVkClearValue(Destination);
 TVkClearValue(Destination):=Temporary;
end;

function TVkClearValueList.CompareItem(const Source,Destination):TpvInt32;
begin
 result:=inherited CompareItem(Source,Destination);
end;

function TVkClearValueList.Add(const Item:TVkClearValue):TVkSizeInt;
begin
 result:=inherited Add(Item);
end;

function TVkClearValueList.Find(const Item:TVkClearValue):TVkSizeInt;
begin
 result:=inherited Find(Item);
end;

procedure TVkClearValueList.Insert(const Index:TVkSizeInt;const Item:TVkClearValue);
begin
 inherited Insert(Index,Item);
end;

procedure TVkClearValueList.Remove(const Item:TVkClearValue);
begin
 inherited Remove(Item);
end;

function VulkanAllocationCallback(UserData:PVkVoid;Size:TVkSize;Alignment:TVkSize;Scope:TVkSystemAllocationScope):PVkVoid; {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 result:=TpvVulkanAllocationManager(UserData).AllocationCallback(Size,Alignment,Scope);
end;

function VulkanReallocationCallback(UserData,Original:PVkVoid;Size:TVkSize;Alignment:TVkSize;Scope:TVkSystemAllocationScope):PVkVoid; {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 result:=TpvVulkanAllocationManager(UserData).ReallocationCallback(Original,Size,Alignment,Scope);
end;

procedure VulkanFreeCallback(UserData,Memory:PVkVoid); {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 TpvVulkanAllocationManager(UserData).FreeCallback(Memory);
end;
                                         
procedure VulkanInternalAllocationCallback(UserData:PVkVoid;Size:TVkSize;Type_:TVkInternalAllocationType;Scope:TVkSystemAllocationScope); {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 TpvVulkanAllocationManager(UserData).InternalAllocationCallback(Size,Type_,Scope);
end;

procedure VulkanInternalFreeCallback(UserData:PVkVoid;Size:TVkSize;Type_:TVkInternalAllocationType;Scope:TVkSystemAllocationScope); {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 TpvVulkanAllocationManager(UserData).InternalFreeCallback(Size,Type_,Scope);
end;

constructor TpvVulkanAllocationManager.Create;
begin
 inherited Create;
 FillChar(fAllocationCallbacks,SizeOf(TVkAllocationCallbacks),#0);
 fAllocationCallbacks.pUserData:=self;
 fAllocationCallbacks.pfnAllocation:=VulkanAllocationCallback;
 fAllocationCallbacks.pfnReallocation:=VulkanReallocationCallback;
 fAllocationCallbacks.pfnFree:=VulkanFreeCallback;
 fAllocationCallbacks.pfnInternalAllocation:=VulkanInternalAllocationCallback;
 fAllocationCallbacks.pfnInternalFree:=VulkanInternalFreeCallback;
end;

destructor TpvVulkanAllocationManager.Destroy;
begin
 inherited Destroy;
end;

function TpvVulkanAllocationManager.AllocationCallback(const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid;
begin
 GetMem(result,Size);
end;

function TpvVulkanAllocationManager.ReallocationCallback(const Original:PVkVoid;const Size:TVkSize;const Alignment:TVkSize;const Scope:TVkSystemAllocationScope):PVkVoid;
begin
 result:=Original;
 ReallocMem(result,Size);
end;

procedure TpvVulkanAllocationManager.FreeCallback(const Memory:PVkVoid);
begin
 FreeMem(Memory);
end;

procedure TpvVulkanAllocationManager.InternalAllocationCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
begin
end;

procedure TpvVulkanAllocationManager.InternalFreeCallback(const Size:TVkSize;const Type_:TVkInternalAllocationType;const Scope:TVkSystemAllocationScope);
begin
end;

constructor TpvVulkanInstance.Create(const aApplicationName:TpvVulkanCharString='Vulkan application';
                                     const aApplicationVersion:TpvUInt32=1;
                                     const aEngineName:TpvVulkanCharString='Vulkan engine';
                                     const aEngineVersion:TpvUInt32=1;
                                     const pAPIVersion:TpvUInt32=VK_API_VERSION_1_0;
                                     const aValidation:boolean=false;
                                     const aAllocationManager:TpvVulkanAllocationManager=nil);
var Index,SubIndex:TpvInt32;
    Count,SubCount:TpvUInt32;
    LayerName:PVkChar;
    LayerProperties:TVkLayerPropertiesArray;
    LayerProperty:PpvVulkanAvailableLayer;
    ExtensionProperties:TVkExtensionPropertiesArray;
    ExtensionProperty:PpvVulkanAvailableExtension;
begin
 inherited Create;

 if not Vulkan.LoadVulkanLibrary then begin
  raise EpvVulkanException.Create('Vulkan load error');
 end;

 if not Vulkan.LoadVulkanGlobalCommands then begin
  raise EpvVulkanException.Create('Vulkan load error');
 end;

 fVulkan:=vk;

 fApplicationName:=aApplicationName;
 fEngineName:=aEngineName;

 fEnabledLayerNameStrings:=nil;
 fEnabledExtensionNameStrings:=nil;

 fRawEnabledLayerNameStrings:=nil;
 fRawEnabledExtensionNameStrings:=nil;

 fInstanceHandle:=VK_NULL_INSTANCE;

 fDebugReportCallbackEXT:=VK_NULL_HANDLE;

 fOnInstanceDebugReportCallback:=nil;

 fInstanceVulkan:=nil;

 fPhysicalDevices:=TpvVulkanPhysicalDeviceList.Create;
 fNeedToEnumeratePhysicalDevices:=false;

 FillChar(fApplicationInfo,SizeOf(TVkApplicationInfo),#0);
 fApplicationInfo.sType:=VK_STRUCTURE_TYPE_APPLICATION_INFO;
 fApplicationInfo.pNext:=nil;
 fApplicationInfo.pApplicationName:=PVkChar(fApplicationName);
 fApplicationInfo.applicationVersion:=aApplicationVersion;
 fApplicationInfo.pEngineName:=PVkChar(fEngineName);
 fApplicationInfo.engineVersion:=aEngineVersion;
 fApplicationInfo.apiVersion:=pAPIVersion;

 fValidation:=aValidation;

 fAllocationManager:=aAllocationManager;

 if assigned(aAllocationManager) then begin
  fAllocationCallbacks:=@aAllocationManager.fAllocationCallbacks;
 end else begin
  fAllocationCallbacks:=nil;
 end;

 fAvailableLayerNames:=TStringList.Create;
 fAvailableExtensionNames:=TStringList.Create;

 fEnabledLayerNames:=TStringList.Create;
 fEnabledExtensionNames:=TStringList.Create;

 LayerProperties:=nil;
 try
  fAvailableLayers:=nil;
  HandleResultCode(fVulkan.EnumerateInstanceLayerProperties(@Count,nil));
  if Count>0 then begin
   SetLength(LayerProperties,Count);
   SetLength(fAvailableLayers,Count);
   HandleResultCode(fVulkan.EnumerateInstanceLayerProperties(@Count,@LayerProperties[0]));
   for Index:=0 to Count-1 do begin
    LayerProperty:=@fAvailableLayers[Index];
    LayerProperty^.LayerName:=LayerProperties[Index].layerName;
    LayerProperty^.SpecVersion:=LayerProperties[Index].specVersion;
    LayerProperty^.ImplementationVersion:=LayerProperties[Index].implementationVersion;
    LayerProperty^.Description:=LayerProperties[Index].description;
    fAvailableLayerNames.Add(String(LayerProperty^.LayerName));
   end;
  end;
 finally
  SetLength(LayerProperties,0);
 end;

 ExtensionProperties:=nil;
 try
  fAvailableExtensions:=nil;
  Count:=0;
  for Index:=-1 to length(fAvailableLayers)-1 do begin
   if Index<0 then begin
    LayerName:=nil;
   end else begin
    LayerName:=PVkChar(fAvailableLayers[Index].layerName);
   end;
   HandleResultCode(fVulkan.EnumerateInstanceExtensionProperties(LayerName,@SubCount,nil));
   if SubCount>0 then begin
    if SubCount>TpvUInt32(length(ExtensionProperties)) then begin
     SetLength(ExtensionProperties,SubCount);
    end;
    SetLength(fAvailableExtensions,Count+SubCount);
    HandleResultCode(fVulkan.EnumerateInstanceExtensionProperties(LayerName,@SubCount,@ExtensionProperties[0]));
    for SubIndex:=0 to SubCount-1 do begin
     ExtensionProperty:=@fAvailableExtensions[Count+TpvUInt32(SubIndex)];
     ExtensionProperty^.LayerIndex:=Index;
     ExtensionProperty^.ExtensionName:=ExtensionProperties[SubIndex].extensionName;
     ExtensionProperty^.SpecVersion:=ExtensionProperties[SubIndex].SpecVersion;
     if fAvailableExtensionNames.IndexOf(String(ExtensionProperty^.ExtensionName))<0 then begin
      fAvailableExtensionNames.Add(String(ExtensionProperty^.ExtensionName));
     end;
    end;
    inc(Count,SubCount);
   end;
  end;
 finally
  SetLength(ExtensionProperties,0);
 end;

 if fValidation then begin
{ if fAvailableExtensionNames.IndexOf('VK_LAYER_LUNARG_standard_validation')>=0 then begin
   fEnabledExtensionNames.Add(VK_EXT_DEBUG_REPORT_EXTENSION_NAME);
   fEnabledLayerNames.Add('VK_LAYER_LUNARG_standard_validation');
  end;}
 end;

end;

destructor TpvVulkanInstance.Destroy;
begin
 if fDebugReportCallbackEXT<>VK_NULL_HANDLE then begin
  fInstanceVulkan.DestroyDebugReportCallbackEXT(fInstanceHandle,fDebugReportCallbackEXT,fAllocationCallbacks);
  fDebugReportCallbackEXT:=VK_NULL_HANDLE;
 end;
 fPhysicalDevices.Free;
 if fInstanceHandle<>VK_NULL_INSTANCE then begin
  fVulkan.DestroyInstance(fInstanceHandle,fAllocationCallbacks);
  fInstanceHandle:=VK_NULL_INSTANCE;
 end;
 fInstanceVulkan.Free;
 fApplicationName:='';
 fEngineName:='';
 fAvailableLayerNames.Free;
 fAvailableExtensionNames.Free;
 fEnabledLayerNames.Free;
 fEnabledExtensionNames.Free;
 SetLength(fAvailableLayers,0);
 SetLength(fAvailableExtensions,0);
 SetLength(fEnabledLayerNameStrings,0);
 SetLength(fRawEnabledLayerNameStrings,0);
 SetLength(fEnabledExtensionNameStrings,0);
 SetLength(fRawEnabledExtensionNameStrings,0);
 inherited Destroy;
end;

procedure TpvVulkanInstance.SetApplicationInfo(const NewApplicationInfo:TVkApplicationInfo);
begin
 fApplicationInfo:=NewApplicationInfo;
 fApplicationName:=fApplicationInfo.pApplicationName;
 fEngineName:=fApplicationInfo.pEngineName;
 fApplicationInfo.pApplicationName:=PVkChar(fApplicationName);
 fApplicationInfo.pEngineName:=PVkChar(fEngineName);
end;

function TpvVulkanInstance.GetApplicationName:TpvVulkanCharString;
begin
 result:=fApplicationName;
end;

procedure TpvVulkanInstance.SetApplicationName(const NewApplicationName:TpvVulkanCharString);
begin
 fApplicationName:=NewApplicationName;
 fApplicationInfo.pApplicationName:=PVkChar(fApplicationName);
end;

function TpvVulkanInstance.GetApplicationVersion:TpvUInt32;
begin
 result:=fApplicationInfo.applicationVersion;
end;

procedure TpvVulkanInstance.SetApplicationVersion(const NewApplicationVersion:TpvUInt32);
begin
 fApplicationInfo.applicationVersion:=NewApplicationVersion;
end;

function TpvVulkanInstance.GetEngineName:TpvVulkanCharString;
begin
 result:=fEngineName;
end;

procedure TpvVulkanInstance.SetEngineName(const NewEngineName:TpvVulkanCharString);
begin
 fEngineName:=NewEngineName;
 fApplicationInfo.pEngineName:=PVkChar(fEngineName);
end;

function TpvVulkanInstance.GetEngineVersion:TpvUInt32;
begin
 result:=fApplicationInfo.engineVersion;
end;

procedure TpvVulkanInstance.SetEngineVersion(const NewEngineVersion:TpvUInt32);
begin
 fApplicationInfo.engineVersion:=NewEngineVersion;
end;

function TpvVulkanInstance.GetAPIVersion:TpvUInt32;
begin
 result:=fApplicationInfo.apiVersion;
end;

procedure TpvVulkanInstance.SetAPIVersion(const NewAPIVersion:TpvUInt32);
begin
 fApplicationInfo.apiVersion:=NewAPIVersion;
end;

procedure TpvVulkanInstance.Initialize;
var i:TpvInt32;
    InstanceCommands:PVulkanCommands;
    InstanceCreateInfo:TVkInstanceCreateInfo;
begin

 if fInstanceHandle=VK_NULL_INSTANCE then begin

  SetLength(fEnabledLayerNameStrings,fEnabledLayerNames.Count);
  SetLength(fRawEnabledLayerNameStrings,fEnabledLayerNames.Count);
  for i:=0 to fEnabledLayerNames.Count-1 do begin
   fEnabledLayerNameStrings[i]:=TpvVulkanCharString(fEnabledLayerNames.Strings[i]);
   fRawEnabledLayerNameStrings[i]:=PVkChar(fEnabledLayerNameStrings[i]);
  end;

  SetLength(fEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  SetLength(fRawEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  for i:=0 to fEnabledExtensionNames.Count-1 do begin
   fEnabledExtensionNameStrings[i]:=TpvVulkanCharString(fEnabledExtensionNames.Strings[i]);
   fRawEnabledExtensionNameStrings[i]:=PVkChar(fEnabledExtensionNameStrings[i]);
  end;

  FillChar(InstanceCreateInfo,SizeOf(TVkInstanceCreateInfo),#0);
  InstanceCreateInfo.sType:=VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
  if length(fEnabledLayerNameStrings)>0 then begin
   InstanceCreateInfo.enabledLayerCount:=length(fEnabledLayerNameStrings);
   InstanceCreateInfo.ppEnabledLayerNames:=@fRawEnabledLayerNameStrings[0];
  end;
  if length(fEnabledExtensionNameStrings)>0 then begin
   InstanceCreateInfo.enabledExtensionCount:=length(fEnabledExtensionNameStrings);
   InstanceCreateInfo.ppEnabledExtensionNames:=@fRawEnabledExtensionNameStrings[0];
  end;

  HandleResultCode(fVulkan.CreateInstance(@InstanceCreateInfo,fAllocationCallbacks,@fInstanceHandle));

  GetMem(InstanceCommands,SizeOf(TVulkanCommands));
  try
   FillChar(InstanceCommands^,SizeOf(TVulkanCommands),#0);
   if LoadVulkanInstanceCommands(fVulkan.Commands.GetInstanceProcAddr,fInstanceHandle,InstanceCommands^) then begin
    fInstanceVulkan:=TVulkan.Create(InstanceCommands^);
   end else begin
    raise EpvVulkanException.Create('Couldn''t load vulkan instance commands');
   end;
  finally
   FreeMem(InstanceCommands);
  end;

  EnumeratePhysicalDevices;

 end;
end;

procedure TpvVulkanInstance.EnumeratePhysicalDevices;
var Index,SubIndex:TpvInt32;
    Count:TpvUInt32;
    PhysicalDevices:TVkPhysicalDeviceArray;
    PhysicalDevice:TpvVulkanPhysicalDevice;
    Found:boolean;
begin
 PhysicalDevices:=nil;
 try
  Count:=0;
  HandleResultCode(fInstanceVulkan.EnumeratePhysicalDevices(fInstanceHandle,@Count,nil));
  if Count>0 then begin
   SetLength(PhysicalDevices,Count);
   HandleResultCode(fInstanceVulkan.EnumeratePhysicalDevices(fInstanceHandle,@Count,@PhysicalDevices[0]));
   for Index:=fPhysicalDevices.Count-1 downto 0 do begin
    Found:=false;
    for SubIndex:=0 to Count-1 do begin
     if fPhysicalDevices[Index].fPhysicalDeviceHandle=PhysicalDevices[SubIndex] then begin
      Found:=true;
      break;
     end;
    end;
    if not Found then begin
     fPhysicalDevices.Delete(Index);
    end;
   end;
   for Index:=0 to Count-1 do begin
    Found:=false;
    for SubIndex:=0 to fPhysicalDevices.Count-1 do begin
     if fPhysicalDevices[SubIndex].fPhysicalDeviceHandle=PhysicalDevices[Index] then begin
      Found:=true;
      break;
     end;
    end;
    if not Found then begin
     PhysicalDevice:=TpvVulkanPhysicalDevice.Create(self,PhysicalDevices[Index]);
     fPhysicalDevices.Add(PhysicalDevice);
    end;
   end;
  end;
 finally
  SetLength(PhysicalDevices,0);
 end;
end;

function TpvVulkanInstanceDebugReportCallbackFunction(flags:TVkDebugReportFlagsEXT;objectType:TVkDebugReportObjectTypeEXT;object_:TVkUInt64;location:TVkSize;messageCode:TpvInt32;const aLayerPrefix:PVkChar;const aMessage:PVkChar;aUserData:PVkVoid):TVkBool32; {$ifdef Windows}stdcall;{$else}{$ifdef Android}{$ifdef cpuarm}hardfloat;{$else}cdecl;{$endif}{$else}cdecl;{$endif}{$endif}
begin
 result:=TpvVulkanInstance(aUserData).DebugReportCallback(flags,objectType,object_,location,messageCode,aLayerPrefix,aMessage);
end;

function TpvVulkanInstance.DebugReportCallback(const flags:TVkDebugReportFlagsEXT;const objectType:TVkDebugReportObjectTypeEXT;const object_:TVkUInt64;const location:TVkSize;messageCode:TpvInt32;const aLayerPrefix:TpvVulkanCharString;const aMessage:TpvVulkanCharString):TVkBool32;
begin
 if assigned(fOnInstanceDebugReportCallback) then begin
  result:=fOnInstanceDebugReportCallback(flags,objectType,object_,location,messageCode,String(aLayerPrefix),String(aMessage));
 end else begin
  result:=VK_FALSE;
 end;
end;

procedure TpvVulkanInstance.InstallDebugReportCallback;
begin
 if (fDebugReportCallbackEXT=VK_NULL_HANDLE) and assigned(fInstanceVulkan.Commands.CreateDebugReportCallbackEXT) then begin
  FillChar(fDebugReportCallbackCreateInfoEXT,SizeOf(TVkDebugReportCallbackCreateInfoEXT),#0);
  fDebugReportCallbackCreateInfoEXT.sType:=VK_STRUCTURE_TYPE_DEBUG_REPORT_CREATE_INFO_EXT;
  fDebugReportCallbackCreateInfoEXT.flags:=TpvUInt32(VK_DEBUG_REPORT_ERROR_BIT_EXT) or TpvUInt32(VK_DEBUG_REPORT_WARNING_BIT_EXT) or TpvUInt32(VK_DEBUG_REPORT_PERFORMANCE_WARNING_BIT_EXT);
  fDebugReportCallbackCreateInfoEXT.pfnCallback:=@TpvVulkanInstanceDebugReportCallbackFunction;
  fDebugReportCallbackCreateInfoEXT.pUserData:=self;
  HandleResultCode(fInstanceVulkan.CreateDebugReportCallbackEXT(fInstanceHandle,@fDebugReportCallbackCreateInfoEXT,fAllocationCallbacks,@fDebugReportCallbackEXT));
 end;
end;

constructor TpvVulkanPhysicalDevice.Create(const aInstance:TpvVulkanInstance;const aPhysicalDevice:TVkPhysicalDevice);
var Index,SubIndex:TpvInt32;
    Count,SubCount:TpvUInt32;
    LayerName:PVkChar;
    LayerProperties:TVkLayerPropertiesArray;
    LayerProperty:PpvVulkanAvailableLayer;
    ExtensionProperties:TVkExtensionPropertiesArray;
    ExtensionProperty:PpvVulkanAvailableExtension;
begin
 inherited Create;

 fInstance:=aInstance;

 fPhysicalDeviceHandle:=aPhysicalDevice;

 fInstance.Commands.GetPhysicalDeviceProperties(fPhysicalDeviceHandle,@fProperties);

 fDeviceName:=fProperties.deviceName;

 fInstance.Commands.GetPhysicalDeviceMemoryProperties(fPhysicalDeviceHandle,@fMemoryProperties);

 fInstance.Commands.GetPhysicalDeviceFeatures(fPhysicalDeviceHandle,@fFeatures);

 fQueueFamilyProperties:=nil;
 Count:=0;
 fInstance.Commands.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@Count,nil);
 if Count>0 then begin
  try
   SetLength(fQueueFamilyProperties,Count);
   fInstance.fVulkan.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@Count,@fQueueFamilyProperties[0]);
  except
   SetLength(fQueueFamilyProperties,0);
   raise;
  end;
 end;

 fAvailableLayerNames:=TStringList.Create;
 fAvailableExtensionNames:=TStringList.Create;

 LayerProperties:=nil;
 try
  fAvailableLayers:=nil;
  HandleResultCode(fInstance.fVulkan.EnumerateDeviceLayerProperties(fPhysicalDeviceHandle,@Count,nil));
  if Count>0 then begin
   SetLength(LayerProperties,Count);
   SetLength(fAvailableLayers,Count);
   HandleResultCode(fInstance.fVulkan.EnumerateDeviceLayerProperties(fPhysicalDeviceHandle,@Count,@LayerProperties[0]));
   for Index:=0 to Count-1 do begin
    LayerProperty:=@fAvailableLayers[Index];
    LayerProperty^.LayerName:=LayerProperties[Index].layerName;
    LayerProperty^.SpecVersion:=LayerProperties[Index].specVersion;
    LayerProperty^.ImplementationVersion:=LayerProperties[Index].implementationVersion;
    LayerProperty^.Description:=LayerProperties[Index].description;
    fAvailableLayerNames.Add(String(LayerProperty^.LayerName));
   end;
  end;
 finally
  SetLength(LayerProperties,0);
 end;

 ExtensionProperties:=nil;
 try
  fAvailableExtensions:=nil;
  Count:=0;
  for Index:=-1 to length(fAvailableLayers)-1 do begin
   if Index<0 then begin
    LayerName:=nil;
   end else begin
    LayerName:=PVkChar(fAvailableLayers[Index].layerName);
   end;
   HandleResultCode(fInstance.fVulkan.EnumerateDeviceExtensionProperties(fPhysicalDeviceHandle,LayerName,@SubCount,nil));
   if SubCount>0 then begin
    if SubCount>TpvUInt32(length(ExtensionProperties)) then begin
     SetLength(ExtensionProperties,SubCount);
    end;
    SetLength(fAvailableExtensions,Count+SubCount);
    HandleResultCode(fInstance.fVulkan.EnumerateDeviceExtensionProperties(fPhysicalDeviceHandle,LayerName,@SubCount,@ExtensionProperties[0]));
    for SubIndex:=0 to SubCount-1 do begin
     ExtensionProperty:=@fAvailableExtensions[Count+TpvUInt32(SubIndex)];
     ExtensionProperty^.LayerIndex:=Index;
     ExtensionProperty^.ExtensionName:=ExtensionProperties[SubIndex].extensionName;
     ExtensionProperty^.SpecVersion:=ExtensionProperties[SubIndex].SpecVersion;
     if fAvailableExtensionNames.IndexOf(String(ExtensionProperty^.ExtensionName))<0 then begin
      fAvailableExtensionNames.Add(String(ExtensionProperty^.ExtensionName));
     end;
    end;
    inc(Count,SubCount);
   end;
  end;
 finally
  SetLength(ExtensionProperties,0);
 end;

end;

destructor TpvVulkanPhysicalDevice.Destroy;
begin
 SetLength(fQueueFamilyProperties,0);
 fAvailableLayerNames.Free;
 fAvailableExtensionNames.Free;
 SetLength(fAvailableLayers,0);
 SetLength(fAvailableExtensions,0);
 inherited Destroy;
end;

function TpvVulkanPhysicalDevice.HasQueueSupportForSparseBindings(const aQueueFamilyIndex:TpvUInt32):boolean;
var QueueFamilyProperties:PVkQueueFamilyProperties;
begin
 result:=false;
 if aQueueFamilyIndex<TpvUInt32(length(fQueueFamilyProperties)) then begin
  QueueFamilyProperties:=@fQueueFamilyProperties[aQueueFamilyIndex];
  if (QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_SPARSE_BINDING_BIT))<>0 then begin
   result:=true;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetFormatProperties(const aFormat:TVkFormat):TVkFormatProperties;
begin
 fInstance.Commands.GetPhysicalDeviceFormatProperties(fPhysicalDeviceHandle,aFormat,@result);
end;

function TpvVulkanPhysicalDevice.GetImageFormatProperties(const aFormat:TVkFormat;
                                                          const aType:TVkImageType;
                                                          const aTiling:TVkImageTiling;
                                                          const aUsageFlags:TVkImageUsageFlags;
                                                          const aCreateFlags:TVkImageCreateFlags):TVkImageFormatProperties;
begin
 fInstance.Commands.GetPhysicalDeviceImageFormatProperties(fPhysicalDeviceHandle,aFormat,aType,aTiling,aUsageFlags,aCreateFlags,@result);
end;

function TpvVulkanPhysicalDevice.GetSparseImageFormatProperties(const aFormat:TVkFormat;
                                                                const aType:TVkImageType;
                                                                const aSamples:TVkSampleCountFlagBits;
                                                                const aUsageFlags:TVkImageUsageFlags;
                                                                const aTiling:TVkImageTiling):TVkSparseImageFormatPropertiesArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 fInstance.Commands.GetPhysicalDeviceSparseImageFormatProperties(fPhysicalDeviceHandle,aFormat,aType,aSamples,aUsageFlags,aTiling,@Count,nil);
 if Count>0 then begin
  SetLength(result,Count);
  fInstance.Commands.GetPhysicalDeviceSparseImageFormatProperties(fPhysicalDeviceHandle,aFormat,aType,aSamples,aUsageFlags,aTiling,@Count,@result[0]);
 end;
end;

function TpvVulkanPhysicalDevice.GetSurfaceSupport(const aQueueFamilyIndex:TpvUInt32;const aSurface:TpvVulkanSurface):boolean;
var Supported:TVkBool32;
begin
 Supported:=0;
 fInstance.Commands.GetPhysicalDeviceSurfaceSupportKHR(fPhysicalDeviceHandle,aQueueFamilyIndex,aSurface.fSurfaceHandle,@Supported);
 result:=Supported<>0;
end;

function TpvVulkanPhysicalDevice.GetSurfaceCapabilities(const aSurface:TpvVulkanSurface):TVkSurfaceCapabilitiesKHR;
begin
 fInstance.Commands.GetPhysicalDeviceSurfaceCapabilitiesKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@result);
end;

function TpvVulkanPhysicalDevice.GetSurfaceFormats(const aSurface:TpvVulkanSurface):TVkSurfaceFormatKHRArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetSurfacePresentModes(const aSurface:TpvVulkanSurface):TVkPresentModeKHRArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceSurfacePresentModesKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceSurfacePresentModesKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetDisplayProperties:TVkDisplayPropertiesKHRArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceDisplayPropertiesKHR(fPhysicalDeviceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceDisplayPropertiesKHR(fPhysicalDeviceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetDisplayPlaneProperties:TVkDisplayPlanePropertiesKHRArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetPhysicalDeviceDisplayPlanePropertiesKHR(fPhysicalDeviceHandle,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetPhysicalDeviceDisplayPlanePropertiesKHR(fPhysicalDeviceHandle,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetDisplayPlaneSupportedDisplays(const aPlaneIndex:TpvUInt32):TVkDisplayKHRArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetDisplayPlaneSupportedDisplaysKHR(fPhysicalDeviceHandle,aPlaneIndex,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetDisplayPlaneSupportedDisplaysKHR(fPhysicalDeviceHandle,aPlaneIndex,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetDisplayModeProperties(const aDisplay:TVkDisplayKHR):TVkDisplayModePropertiesKHRArray;
var Count:TpvUInt32;
begin
 result:=nil;
 Count:=0;
 if fInstance.Commands.GetDisplayModePropertiesKHR(fPhysicalDeviceHandle,aDisplay,@Count,nil)=VK_SUCCESS then begin
  if Count>0 then begin
   try
    SetLength(result,Count);
    HandleResultCode(fInstance.Commands.GetDisplayModePropertiesKHR(fPhysicalDeviceHandle,aDisplay,@Count,@result[0]));
   except
    SetLength(result,0);
    raise;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetMemoryType(const aTypeBits:TpvUInt32;const aProperties:TVkFlags):TpvUInt32;
var i:TpvUInt32;
    DeviceMemoryProperties:TVkPhysicalDeviceMemoryProperties;
begin
 result:=TpvUInt32(TpvInt32(-1));
 vkGetPhysicalDeviceMemoryProperties(fPhysicalDeviceHandle,@DeviceMemoryProperties);
 for i:=0 to 31 do begin
  if (aTypeBits and (TpvUInt32(1) shl i))<>0 then begin
   if (DeviceMemoryProperties.MemoryTypes[i].PropertyFlags and aProperties)=aProperties then begin
    result:=i;
    exit;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetBestSupportedDepthFormat(const aWithStencil:boolean):TVkFormat;
const Formats:array[0..4] of TVkFormat=(VK_FORMAT_D32_SFLOAT_S8_UINT,
                                        VK_FORMAT_D32_SFLOAT,
                                        VK_FORMAT_D24_UNORM_S8_UINT,
                                        VK_FORMAT_D16_UNORM_S8_UINT,
                                        VK_FORMAT_D16_UNORM);
      WithStencilFormats:array[0..2] of TVkFormat=(VK_FORMAT_D32_SFLOAT_S8_UINT,
                                                   VK_FORMAT_D24_UNORM_S8_UINT,
                                                   VK_FORMAT_D16_UNORM_S8_UINT);
var i:TpvInt32;
    Format:TVkFormat;
    FormatProperties:TVkFormatProperties;
begin
 result:=VK_FORMAT_UNDEFINED;
 if aWithStencil then begin
  for i:=low(WithStencilFormats) to high(WithStencilFormats) do begin
   Format:=WithStencilFormats[i];
   fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fPhysicalDeviceHandle,Format,@FormatProperties);
   if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))<>0 then begin
    result:=Format;
    exit;
   end;
  end;
 end else begin
  for i:=low(Formats) to high(Formats) do begin
   Format:=Formats[i];
   fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fPhysicalDeviceHandle,Format,@FormatProperties);
   if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))<>0 then begin
    result:=Format;
    exit;
   end;
  end;
 end;
end;

function TpvVulkanPhysicalDevice.GetQueueNodeIndex(const aSurface:TpvVulkanSurface;const aQueueFlagBits:TVkQueueFlagBits):TpvInt32;
var Index:TpvInt32;
    QueueCount:TpvUInt32;
    QueueProperties:array of TVkQueueFamilyProperties;
    SupportsPresent:TVkBool32;
begin
 result:=-1;
 fInstance.fVulkan.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@QueueCount,nil);
 QueueProperties:=nil;
 SetLength(QueueProperties,QueueCount);
 try
  fInstance.fVulkan.GetPhysicalDeviceQueueFamilyProperties(fPhysicalDeviceHandle,@QueueCount,@QueueProperties[0]);
  for Index:=0 to QueueCount-1 do begin
   fInstance.fVulkan.GetPhysicalDeviceSurfaceSupportKHR(fPhysicalDeviceHandle,Index,aSurface.fSurfaceHandle,@SupportsPresent);
   if ((QueueProperties[Index].QueueFlags and TVkQueueFlags(aQueueFlagBits))<>0) and (SupportsPresent=VK_TRUE) then begin
    result:=Index;
    break;
   end;
  end;
 finally
  SetLength(QueueProperties,0);
 end;
end;

function TpvVulkanPhysicalDevice.GetSurfaceFormat(const aSurface:TpvVulkanSurface;const aSRGB:boolean=false):TVkSurfaceFormatKHR;
var FormatCount,Index,BestIndex:TpvUInt32;
    SurfaceFormats:TVkSurfaceFormatKHRArray;
begin
 SurfaceFormats:=nil;
 try

  FormatCount:=0;
  HandleResultCode(vkGetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@FormatCount,nil));

  if FormatCount>0 then begin
   SetLength(SurfaceFormats,FormatCount);
   HandleResultCode(vkGetPhysicalDeviceSurfaceFormatsKHR(fPhysicalDeviceHandle,aSurface.fSurfaceHandle,@FormatCount,@SurfaceFormats[0]));
  end;

  if FormatCount=0 then begin
{$if defined(Android)}
   if aSRGB then begin
    result.Format:=VK_FORMAT_R8G8B8A8_SRGB;
   end else begin
    result.Format:=VK_FORMAT_R8G8B8A8_UNORM;
   end;
{$else}
   if aSRGB then begin
    result.Format:=VK_FORMAT_B8G8R8A8_SRGB;
   end else begin
    result.Format:=VK_FORMAT_B8G8R8A8_UNORM;
   end;
{$ifend}
   result.ColorSpace:=VK_COLORSPACE_SRGB_NONLINEAR_KHR;
  end else if (FormatCount=1) and (SurfaceFormats[0].Format=VK_FORMAT_UNDEFINED) then begin
{$if defined(Android)}
   if aSRGB then begin
    result.Format:=VK_FORMAT_R8G8B8A8_SRGB;
   end else begin
    result.Format:=VK_FORMAT_R8G8B8A8_UNORM;
   end;
{$else}
   if aSRGB then begin
    result.Format:=VK_FORMAT_B8G8R8A8_SRGB;
   end else begin
    result.Format:=VK_FORMAT_B8G8R8A8_UNORM;
   end;
{$ifend}
   result.ColorSpace:=SurfaceFormats[0].colorSpace;
  end else begin
   BestIndex:=0;
   for Index:=0 to FormatCount-1 do begin
    if (aSRGB and (SurfaceFormats[Index].format in [VK_FORMAT_R8G8B8A8_SRGB,VK_FORMAT_B8G8R8A8_SRGB])) or
       ((not aSRGB) and (SurfaceFormats[Index].format in [VK_FORMAT_R8G8B8A8_UNORM,VK_FORMAT_B8G8R8A8_UNORM])) then begin
     BestIndex:=Index;
     break;
    end;
   end;
   result:=SurfaceFormats[BestIndex];
  end;

 finally
  SetLength(SurfaceFormats,0);
 end;

end;

function TpvVulkanPhysicalDeviceList.GetItem(const Index:TVkSizeInt):TpvVulkanPhysicalDevice;
begin
 result:=TpvVulkanPhysicalDevice(inherited Items[Index]);
end;

procedure TpvVulkanPhysicalDeviceList.SetItem(const Index:TVkSizeInt;const Item:TpvVulkanPhysicalDevice);
begin
 inherited Items[Index]:=Item;
end;

(*constructor TpvVulkanSurface.Create(const aInstance:TpvVulkanInstance;
{$if defined(Android)}
                                      const aWindow:PANativeWindow
{$elseif defined(Mir)}
                                      const aConnection:PMirConnection;const aMirSurface:PMirSurface
{$elseif defined(Wayland)}
                                      const aDisplay:Pwl_display;const aSurface:Pwl_surface
{$elseif defined(Windows)}
                                      const aInstanceHandle,aWindowHandle:Windows.THandle
{$elseif defined(XLIB)}
                                      const aDisplay:PDisplay;const aWindow:TWindow
{$elseif defined(XCB)}
                                      const aConnection:Pxcb_connection;aWindow:Pxcb_window
{$ifend}
                                 );*)

constructor TpvVulkanSurface.Create(const aInstance:TpvVulkanInstance;const aSurfaceCreateInfo:TpvVulkanSurfaceCreateInfo);
begin
 inherited Create;

 fInstance:=aInstance;

 fSurfaceHandle:=VK_NULL_HANDLE;

 fSurfaceCreateInfo:=aSurfaceCreateInfo;

 case fSurfaceCreateInfo.sType of
{$if defined(Android)}
  VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR:begin
   HandleResultCode(fInstance.fVulkan.CreateAndroidSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo.Android,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(Mir) and defined(Unix)}
  VK_STRUCTURE_TYPE_MIR_SURFACE_CREATE_INFO_KHR:begin
   HandleResultCode(fInstance.fVulkan.CreateMirSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo.Mir,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(Wayland) and defined(Unix)}
  VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR:begin
   HandleResultCode(fInstance.fVulkan.CreateWaylandSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo.Wayland,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(Windows)}
  VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR:begin
   HandleResultCode(fInstance.fVulkan.CreateWin32SurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo.Win32,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(XCB) and defined(Unix)}
  VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR:begin
   HandleResultCode(fInstance.fVulkan.CreateXCBSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo.XCB,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(XLIB) and defined(Unix)}
  VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR:begin
   HandleResultCode(fInstance.fVulkan.CreateXLIBSurfaceKHR(fInstance.fInstanceHandle,@fSurfaceCreateInfo.XLIB,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(MoltenVK_IOS) and defined(Darwin)}
  VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK:begin
   HandleResultCode(fInstance.fVulkan.CreateIOSSurfaceMVK(fInstance.fInstanceHandle,@fSurfaceCreateInfo.MoltenVK_IOS,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
{$if defined(MoltenVK_MacOS) and defined(Darwin)}
  VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK:begin
   HandleResultCode(fInstance.fVulkan.CreateMacOSSurfaceMVK(fInstance.fInstanceHandle,@fSurfaceCreateInfo.MoltenVK_MacOS,fInstance.fAllocationCallbacks,@fSurfaceHandle));
  end;
{$ifend}
  else begin
   HandleResultCode(VK_ERROR_INCOMPATIBLE_DRIVER);
  end;
 end;

end;

constructor TpvVulkanSurface.CreateHandle(const aInstance:TpvVulkanInstance;const aSurfaceHandle:TVkSurfaceKHR);
begin

 inherited Create;

 fInstance:=aInstance;

 fSurfaceHandle:=aSurfaceHandle;

 FillChar(fSurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);

end;

{$if defined(Android)}
constructor TpvVulkanSurface.CreateAndroid(const aInstance:TpvVulkanInstance;const aWindow:PVkAndroidANativeWindow);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.Android.sType:=VK_STRUCTURE_TYPE_ANDROID_SURFACE_CREATE_INFO_KHR;
 SurfaceCreateInfo.Android.window:=aWindow;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(Mir) and defined(Unix)}
constructor TpvVulkanSurface.CreateMir(const aInstance:TpvVulkanInstance;const aConnection:PVkMirConnection;const aSurface:PVkMirSurface);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.Mir.sType:=VK_STRUCTURE_TYPE_MIR_SURFACE_CREATE_INFO_KHR;
 SurfaceCreateInfo.Mir.connection:=aConnection;
 SurfaceCreateInfo.Mir.mirSurface:=aSurface;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(Wayland) and defined(Unix)}
constructor TpvVulkanSurface.CreateWayland(const aInstance:TpvVulkanInstance;const aDisplay:PVkWaylandDisplay;const aSurface:PVkWaylandSurface);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.Wayland.sType:=VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR;
 SurfaceCreateInfo.Wayland.display:=aDisplay;
 SurfaceCreateInfo.Wayland.surface:=aSurface;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(Windows)}
constructor TpvVulkanSurface.CreateWin32(const aInstance:TpvVulkanInstance;const aInstanceHandle,aWindowHandle:Windows.THandle);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.Win32.sType:=VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
 SurfaceCreateInfo.Win32.hinstance_:=aInstanceHandle;
 SurfaceCreateInfo.Win32.hwnd_:=aWindowHandle;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(XCB) and defined(Unix)}
constructor TpvVulkanSurface.CreateXCB(const aInstance:TpvVulkanInstance;const aConnection:PVkXCBConnection;const aWindow:TVkXCBWindow);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.XCB.sType:=VK_STRUCTURE_TYPE_XCB_SURFACE_CREATE_INFO_KHR;
 SurfaceCreateInfo.XCB.connection:=aConnection;
 SurfaceCreateInfo.XCB.window:=aWindow;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(XLIB) and defined(Unix)}
constructor TpvVulkanSurface.CreateXLIB(const aInstance:TpvVulkanInstance;const aDisplay:PVkXLIBDisplay;const aWindow:TVkXLIBWindow);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.XLIB.sType:=VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR;
 SurfaceCreateInfo.XLIB.dpy:=aDisplay;
 SurfaceCreateInfo.XLIB.window:=aWindow;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(MoltenVK_IOS) and defined(Darwin)}
constructor TpvVulkanSurface.CreateMoltenVK_IOS(const aInstance:TpvVulkanInstance;const aView:PVkVoid);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.MoltenVK_IOS.sType:=VK_STRUCTURE_TYPE_IOS_SURFACE_CREATE_INFO_MVK;
 SurfaceCreateInfo.MoltenVK_IOS.aView:=aView;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

{$if defined(MoltenVK_MacOS) and defined(Darwin)}
constructor TpvVulkanSurface.CreateMoltenVK_MacOS(const aInstance:TpvVulkanInstance;const aView:PVkVoid);
var SurfaceCreateInfo:TpvVulkanSurfaceCreateInfo;
begin
 FillChar(SurfaceCreateInfo,SizeOf(TpvVulkanSurfaceCreateInfo),#0);
 SurfaceCreateInfo.MoltenVK_MacOS.sType:=VK_STRUCTURE_TYPE_MACOS_SURFACE_CREATE_INFO_MVK;
 SurfaceCreateInfo.MoltenVK_MacOS.aView:=aView;
 Create(aInstance,SurfaceCreateInfo);
end;
{$ifend}

destructor TpvVulkanSurface.Destroy;
begin
 if fSurfaceHandle<>VK_NULL_HANDLE then begin
  fInstance.fVulkan.DestroySurfaceKHR(fInstance.fInstanceHandle,fSurfaceHandle,fInstance.fAllocationCallbacks);
  fSurfaceHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanDevice.Create(const aInstance:TpvVulkanInstance;
                                   const aPhysicalDevice:TpvVulkanPhysicalDevice=nil;
                                   const aSurface:TpvVulkanSurface=nil;
                                   const aAllocationManager:TpvVulkanAllocationManager=nil);
var Index,SubIndex:TpvInt32;
    BestPhysicalDevice,CurrentPhysicalDevice:TpvVulkanPhysicalDevice;
    BestScore,CurrentScore,Temp:int64;
    OK:boolean;
begin
 inherited Create;

 fInstance:=aInstance;

 fDeviceQueueCreateInfoList:=TpvVulkanDeviceQueueCreateInfoList.Create;

 fDeviceQueueCreateInfos:=nil;

 fEnabledLayerNameStrings:=nil;
 fEnabledExtensionNameStrings:=nil;

 fRawEnabledLayerNameStrings:=nil;
 fRawEnabledExtensionNameStrings:=nil;

 if assigned(aAllocationManager) then begin
  fAllocationManager:=aAllocationManager;
 end else begin
  fAllocationManager:=fInstance.fAllocationManager;
 end;

 if assigned(fAllocationManager) then begin
  fAllocationCallbacks:=@fAllocationManager.fAllocationCallbacks;
 end else begin
  fAllocationCallbacks:=nil;
 end;

 fSurface:=aSurface;

 fDeviceHandle:=VK_NULL_HANDLE;

 fDeviceVulkan:=nil;

 fQueues:=nil;

 fUniversalQueueFamilyIndex:=-1;
 fPresentQueueFamilyIndex:=-1;
 fGraphicsQueueFamilyIndex:=-1;
 fComputeQueueFamilyIndex:=-1;
 fTransferQueueFamilyIndex:=-1;

 fUniversalQueue:=nil;
 fPresentQueue:=nil;
 fGraphicsQueue:=nil;
 fComputeQueue:=nil;
 fTransferQueue:=nil;

 if assigned(aPhysicalDevice) then begin
  fPhysicalDevice:=aPhysicalDevice;
 end else begin
  BestPhysicalDevice:=nil;
  BestScore:=-$7fffffffffffffff;
  for Index:=0 to fInstance.fPhysicalDevices.Count-1 do begin
   CurrentPhysicalDevice:=fInstance.fPhysicalDevices[Index];
   CurrentScore:=0;
   case CurrentPhysicalDevice.fProperties.deviceType of
    VK_PHYSICAL_DEVICE_TYPE_OTHER:begin
     CurrentScore:=CurrentScore or (int64(1) shl 60);
    end;
    VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:begin
     CurrentScore:=CurrentScore or (int64(3) shl 60);
    end;
    VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:begin
     CurrentScore:=CurrentScore or (int64(4) shl 60);
    end;
    VK_PHYSICAL_DEVICE_TYPE_VIRTUAL_GPU:begin
     CurrentScore:=CurrentScore or (int64(2) shl 60);
    end;
    else begin
     CurrentScore:=CurrentScore or (int64(0) shl 60);
    end;
   end;
   OK:=false;
   for SubIndex:=0 to length(CurrentPhysicalDevice.fQueueFamilyProperties)-1 do begin
    if assigned(aSurface) and not CurrentPhysicalDevice.GetSurfaceSupport(SubIndex,aSurface) then begin
     continue;
    end;
    OK:=true;
    Temp:=0;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TpvInt32(VK_QUEUE_GRAPHICS_BIT))<>0 then begin
     inc(Temp);
    end;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TpvInt32(VK_QUEUE_COMPUTE_BIT))<>0 then begin
     inc(Temp);
    end;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TpvInt32(VK_QUEUE_TRANSFER_BIT))<>0 then begin
     inc(Temp);
    end;
    if (CurrentPhysicalDevice.fQueueFamilyProperties[SubIndex].queueFlags and TpvInt32(VK_QUEUE_SPARSE_BINDING_BIT))<>0 then begin
     inc(Temp);
    end;
    CurrentScore:=CurrentScore or (int64(Temp) shl 55);
   end;
   if not OK then begin
    continue;
   end;
   if (BestScore>CurrentScore) or not assigned(BestPhysicalDevice) then begin
    BestPhysicalDevice:=CurrentPhysicalDevice;
    BestScore:=CurrentScore;
   end;
  end;
  if assigned(BestPhysicalDevice) then begin
   fPhysicalDevice:=BestPhysicalDevice;
  end else begin
   raise EpvVulkanException.Create('No suitable vulkan device found');
  end;
 end;

 fEnabledLayerNames:=TStringList.Create;
 fEnabledExtensionNames:=TStringList.Create;

 fEnabledFeatures:=fPhysicalDevice.fFeatures;

 fPointerToEnabledFeatures:=@fEnabledFeatures;

 fMemoryManager:=TpvVulkanDeviceMemoryManager.Create(self);

 fCanvasCommon:=nil;

end;

destructor TpvVulkanDevice.Destroy;
var Index:TpvInt32;
begin
 FreeAndNil(fCanvasCommon);
 for Index:=0 to length(fQueues)-1 do begin
  if assigned(fQueues[Index]) then begin
   fQueues[Index].Free;
   fQueues[Index]:=nil;
  end;
 end;
 SetLength(fQueues,0);
 fMemoryManager.Free;
 fDeviceVulkan.Free;
 if fDeviceHandle<>VK_NULL_HANDLE then begin
  fInstance.Commands.DestroyDevice(fDeviceHandle,fAllocationCallbacks);
  fDeviceHandle:=VK_NULL_HANDLE;
 end;
 SetLength(fDeviceQueueCreateInfos,0);
 fDeviceQueueCreateInfoList.Free;
 fEnabledLayerNames.Free;
 fEnabledExtensionNames.Free;
 SetLength(fEnabledLayerNameStrings,0);
 SetLength(fRawEnabledLayerNameStrings,0);
 SetLength(fEnabledExtensionNameStrings,0);
 SetLength(fRawEnabledExtensionNameStrings,0);
 inherited Destroy;
end;

procedure TpvVulkanDevice.AddQueue(const aQueueFamilyIndex:TpvUInt32;const aQueuePriorities:array of TpvFloat;const aSurface:TpvVulkanSurface=nil);
var QueueFamilyProperties:PVkQueueFamilyProperties;
begin
 if aQueueFamilyIndex<TpvUInt32(length(fPhysicalDevice.fQueueFamilyProperties)) then begin
  QueueFamilyProperties:=@fPhysicalDevice.fQueueFamilyProperties[aQueueFamilyIndex];
  if (((QueueFamilyProperties.queueFlags and (TpvUInt32(VK_QUEUE_GRAPHICS_BIT) or
                                              TpvUInt32(VK_QUEUE_COMPUTE_BIT) or
                                              TpvUInt32(VK_QUEUE_TRANSFER_BIT)))=(TpvUInt32(VK_QUEUE_GRAPHICS_BIT) or
                                                                                  TpvUInt32(VK_QUEUE_COMPUTE_BIT) or
                                                                                  TpvUInt32(VK_QUEUE_TRANSFER_BIT))) and (fUniversalQueueFamilyIndex<0)) and
     ((assigned(aSurface) and fPhysicalDevice.GetSurfaceSupport(aQueueFamilyIndex,aSurface)) or not assigned(aSurface)) then begin
   fUniversalQueueFamilyIndex:=aQueueFamilyIndex;
  end;
  if (fPresentQueueFamilyIndex<0) and ((assigned(aSurface) and fPhysicalDevice.GetSurfaceSupport(aQueueFamilyIndex,aSurface)) or not assigned(aSurface)) then begin
   fPresentQueueFamilyIndex:=aQueueFamilyIndex;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_GRAPHICS_BIT))<>0) and (fGraphicsQueueFamilyIndex<0) then begin
   fGraphicsQueueFamilyIndex:=aQueueFamilyIndex;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_COMPUTE_BIT))<>0) and (fComputeQueueFamilyIndex<0) then begin
   fComputeQueueFamilyIndex:=aQueueFamilyIndex;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_TRANSFER_BIT))<>0) and (fTransferQueueFamilyIndex<0) then begin
   fTransferQueueFamilyIndex:=aQueueFamilyIndex;
  end;
  fDeviceQueueCreateInfoList.Add(TpvVulkanDeviceQueueCreateInfo.Create(aQueueFamilyIndex,aQueuePriorities));
 end else begin
  raise EpvVulkanException.Create('Queue family index out of bounds');
 end;
end;

procedure TpvVulkanDevice.AddQueues(const aUniversal:boolean=true;
                                    const aPresent:boolean=true;
                                    const aGraphics:boolean=true;
                                    const aCompute:boolean=true;
                                    const aTransfer:boolean=true;
                                    const aSparseBinding:boolean=false;
                                    const aSurface:TpvVulkanSurface=nil);
var Index:TpvInt32;
    DoAdd:boolean;
    QueueFamilyProperties:PVkQueueFamilyProperties;
begin
 for Index:=0 to length(fPhysicalDevice.fQueueFamilyProperties)-1 do begin
  DoAdd:=false;
  QueueFamilyProperties:=@fPhysicalDevice.fQueueFamilyProperties[Index];
  if (((QueueFamilyProperties.queueFlags and (TpvUInt32(VK_QUEUE_GRAPHICS_BIT) or
                                              TpvUInt32(VK_QUEUE_COMPUTE_BIT) or
                                              TpvUInt32(VK_QUEUE_TRANSFER_BIT)))=(TpvUInt32(VK_QUEUE_GRAPHICS_BIT) or
                                                                                  TpvUInt32(VK_QUEUE_COMPUTE_BIT) or
                                                                                  TpvUInt32(VK_QUEUE_TRANSFER_BIT))) and (fUniversalQueueFamilyIndex<0)) and
     ((assigned(aSurface) and fPhysicalDevice.GetSurfaceSupport(Index,aSurface)) or not assigned(aSurface)) then begin
   fUniversalQueueFamilyIndex:=Index;
   if aUniversal then begin
    DoAdd:=true;
   end;
  end;
  if (fPresentQueueFamilyIndex<0) and ((assigned(aSurface) and fPhysicalDevice.GetSurfaceSupport(Index,aSurface)) or not assigned(aSurface)) then begin
   fPresentQueueFamilyIndex:=Index;
   if aPresent then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_GRAPHICS_BIT))<>0) and (fGraphicsQueueFamilyIndex<0) then begin
   fGraphicsQueueFamilyIndex:=Index;
   if aGraphics then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_COMPUTE_BIT))<>0) and (fComputeQueueFamilyIndex<0) then begin
   fComputeQueueFamilyIndex:=Index;
   if aCompute then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_TRANSFER_BIT))<>0) and (fTransferQueueFamilyIndex<0) then begin
   fTransferQueueFamilyIndex:=Index;
   if aTransfer then begin
    DoAdd:=true;
   end;
  end;
  if ((QueueFamilyProperties.queueFlags and TpvUInt32(VK_QUEUE_SPARSE_BINDING_BIT))=0) and aSparseBinding then begin
   raise EpvVulkanException.Create('Only unsatisfactory device queue families available');
  end;
  if DoAdd then begin
   fDeviceQueueCreateInfoList.Add(TpvVulkanDeviceQueueCreateInfo.Create(Index,[1.0]));
  end;
 end;
 if ((fTransferQueueFamilyIndex<0) and aTransfer) and
    (((fGraphicsQueueFamilyIndex>=0) and aGraphics) or
     ((fComputeQueueFamilyIndex>=0) and aCompute)) then begin
  // https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkQueueFamilyProperties.html
  // Quote: "All commands that are allowed on a queue that supports transfer operations are
  //         also allowed on a queue that supports either graphics or compute operations thus
  //         if the capabilities of a queue family include VK_QUEUE_GRAPHICS_BIT or
  //         VK_QUEUE_COMPUTE_BIT then reporting the VK_QUEUE_TRANSFER_BIT capability separately
  //         for that queue family is optional."
  if (fGraphicsQueueFamilyIndex>=0) and aGraphics then begin
   fTransferQueueFamilyIndex:=fGraphicsQueueFamilyIndex;
  end else if (fComputeQueueFamilyIndex>=0) and aCompute then begin
   fTransferQueueFamilyIndex:=fComputeQueueFamilyIndex;
  end;
 end;
 if ((fUniversalQueueFamilyIndex<0) and aUniversal) or
    ((fPresentQueueFamilyIndex<0) and aPresent) or
    ((fGraphicsQueueFamilyIndex<0) and aGraphics) or
    ((fComputeQueueFamilyIndex<0) and aCompute) or
    ((fTransferQueueFamilyIndex<0) and aTransfer) then begin
  raise EpvVulkanException.Create('Only unsatisfactory device queue families available');
 end;
end;

procedure TpvVulkanDevice.Initialize;
var Index:TpvInt32;
    DeviceQueueCreateInfo:PVkDeviceQueueCreateInfo;
    SrcDeviceQueueCreateInfo:TpvVulkanDeviceQueueCreateInfo;
    DeviceCommands:PVulkanCommands;
    Queue:TVkQueue;
    DeviceCreateInfo:TVkDeviceCreateInfo;
begin
 if fDeviceHandle=VK_NULL_HANDLE then begin

  SetLength(fEnabledLayerNameStrings,fEnabledLayerNames.Count);
  SetLength(fRawEnabledLayerNameStrings,fEnabledLayerNames.Count);
  for Index:=0 to fEnabledLayerNames.Count-1 do begin
   fEnabledLayerNameStrings[Index]:=TpvVulkanCharString(fEnabledLayerNames.Strings[Index]);
   fRawEnabledLayerNameStrings[Index]:=PVkChar(fEnabledLayerNameStrings[Index]);
  end;

  SetLength(fEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  SetLength(fRawEnabledExtensionNameStrings,fEnabledExtensionNames.Count);
  for Index:=0 to fEnabledExtensionNames.Count-1 do begin
   fEnabledExtensionNameStrings[Index]:=TpvVulkanCharString(fEnabledExtensionNames.Strings[Index]);
   fRawEnabledExtensionNameStrings[Index]:=PVkChar(fEnabledExtensionNameStrings[Index]);
  end;

  SetLength(fDeviceQueueCreateInfos,fDeviceQueueCreateInfoList.Count);
  for Index:=0 to fDeviceQueueCreateInfoList.Count-1 do begin
   SrcDeviceQueueCreateInfo:=fDeviceQueueCreateInfoList[Index];
   DeviceQueueCreateInfo:=@fDeviceQueueCreateInfos[Index];
   FillChar(DeviceQueueCreateInfo^,SizeOf(TVkDeviceQueueCreateInfo),#0);
   DeviceQueueCreateInfo^.sType:=VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
   DeviceQueueCreateInfo^.queueFamilyIndex:=SrcDeviceQueueCreateInfo.fQueueFamilyIndex;
   DeviceQueueCreateInfo^.queueCount:=length(SrcDeviceQueueCreateInfo.fQueuePriorities);
   if DeviceQueueCreateInfo^.queueCount>0 then begin
    DeviceQueueCreateInfo^.pQueuePriorities:=@SrcDeviceQueueCreateInfo.fQueuePriorities[0];
   end;
  end;

  FillChar(DeviceCreateInfo,SizeOf(TVkDeviceCreateInfo),#0);
  DeviceCreateInfo.sType:=VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
  if length(fDeviceQueueCreateInfos)>0 then begin
   DeviceCreateInfo.queueCreateInfoCount:=length(fDeviceQueueCreateInfos);
   DeviceCreateInfo.pQueueCreateInfos:=@fDeviceQueueCreateInfos[0];
  end;
  if length(fEnabledLayerNameStrings)>0 then begin
   DeviceCreateInfo.enabledLayerCount:=length(fEnabledLayerNameStrings);
   DeviceCreateInfo.ppEnabledLayerNames:=@fRawEnabledLayerNameStrings[0];
  end;
  if length(fEnabledExtensionNameStrings)>0 then begin
   DeviceCreateInfo.enabledExtensionCount:=length(fEnabledExtensionNameStrings);
   DeviceCreateInfo.ppEnabledExtensionNames:=@fRawEnabledExtensionNameStrings[0];
  end;
  DeviceCreateInfo.pEnabledFeatures:=@fEnabledFeatures;
  HandleResultCode(fInstance.Commands.CreateDevice(fPhysicalDevice.fPhysicalDeviceHandle,@DeviceCreateInfo,fAllocationCallbacks,@fDeviceHandle));

  GetMem(DeviceCommands,SizeOf(TVulkanCommands));
  try
   FillChar(DeviceCommands^,SizeOf(TVulkanCommands),#0);
   if LoadVulkanDeviceCommands(fInstance.Commands.Commands.GetDeviceProcAddr,fDeviceHandle,DeviceCommands^) then begin
    fDeviceVulkan:=TVulkan.Create(DeviceCommands^);
   end else begin
    raise EpvVulkanException.Create('Couldn''t load vulkan device commands');
   end;
  finally
   FreeMem(DeviceCommands);
  end;

  if (fTransferQueueFamilyIndex<0) and ((fGraphicsQueueFamilyIndex>=0) or (fComputeQueueFamilyIndex>=0)) then begin
   // https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkQueueFamilyProperties.html
   // Quote: "All commands that are allowed on a queue that supports transfer operations are
   //         also allowed on a queue that supports either graphics or compute operations thus
   //         if the capabilities of a queue family include VK_QUEUE_GRAPHICS_BIT or
   //         VK_QUEUE_COMPUTE_BIT then reporting the VK_QUEUE_TRANSFER_BIT capability separately
   //         for that queue family is optional."
   if fGraphicsQueueFamilyIndex>=0 then begin
    fTransferQueueFamilyIndex:=fGraphicsQueueFamilyIndex;
   end else if fComputeQueueFamilyIndex>=0 then begin
    fTransferQueueFamilyIndex:=fComputeQueueFamilyIndex;
   end;
  end;

  SetLength(fQueues,length(fPhysicalDevice.fQueueFamilyProperties));
  for Index:=0 to length(fPhysicalDevice.fQueueFamilyProperties)-1 do begin
   if (Index=fUniversalQueueFamilyIndex) or
      (Index=fPresentQueueFamilyIndex) or
      (Index=fGraphicsQueueFamilyIndex) or
      (Index=fComputeQueueFamilyIndex) or
      (Index=fTransferQueueFamilyIndex) then begin
    fDeviceVulkan.GetDeviceQueue(fDeviceHandle,Index,0,@Queue);
    fQueues[Index]:=TpvVulkanQueue.Create(self,Queue,Index);
   end else begin
    fQueues[Index]:=nil;
   end;
  end;

  if fUniversalQueueFamilyIndex>=0 then begin
   fUniversalQueue:=fQueues[fUniversalQueueFamilyIndex];
  end else begin
   fUniversalQueue:=nil;
  end;

  if fPresentQueueFamilyIndex>=0 then begin
   fPresentQueue:=fQueues[fPresentQueueFamilyIndex];
  end else begin
   fPresentQueue:=nil;
  end;

  if fGraphicsQueueFamilyIndex>=0 then begin
   fGraphicsQueue:=fQueues[fGraphicsQueueFamilyIndex];
  end else begin
   fGraphicsQueue:=nil;
  end;

  if fComputeQueueFamilyIndex>=0 then begin
   fComputeQueue:=fQueues[fComputeQueueFamilyIndex];
  end else begin
   fComputeQueue:=nil;
  end;

  if fTransferQueueFamilyIndex>=0 then begin
   fTransferQueue:=fQueues[fTransferQueueFamilyIndex];
  end else begin
   fTransferQueue:=nil;
  end;

 end;
end;

procedure TpvVulkanDevice.WaitIdle;
begin
 fDeviceVulkan.DeviceWaitIdle(fDeviceHandle);
end;

constructor TpvVulkanDeviceQueueCreateInfo.Create(const aQueueFamilyIndex:TpvUInt32;const aQueuePriorities:array of TpvFloat);
begin
 inherited Create;
 fQueueFamilyIndex:=aQueueFamilyIndex;
 SetLength(fQueuePriorities,length(aQueuePriorities));
 if length(aQueuePriorities)>0 then begin
  Move(aQueuePriorities[0],fQueuePriorities[0],length(aQueuePriorities)*SizeOf(TpvFloat));
 end;
end;

destructor TpvVulkanDeviceQueueCreateInfo.Destroy;
begin
 SetLength(fQueuePriorities,0);
 inherited Destroy;
end;

function TpvVulkanDeviceQueueCreateInfoList.GetItem(const Index:TVkSizeInt):TpvVulkanDeviceQueueCreateInfo;
begin
 result:=TpvVulkanDeviceQueueCreateInfo(inherited Items[Index]);
end;

procedure TpvVulkanDeviceQueueCreateInfoList.SetItem(const Index:TVkSizeInt;const Item:TpvVulkanDeviceQueueCreateInfo);
begin
 inherited Items[Index]:=Item;
end;

constructor TpvVulkanResource.Create;
begin
 inherited Create;
 fDevice:=nil;
 fOwnsResource:=false;
end;

destructor TpvVulkanResource.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanResource.Clear;
begin
 fDevice:=nil;
 fOwnsResource:=false;
end;

constructor TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Create(const aKey:TpvUInt64=0;
                                                                   const aValue:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue=nil;
                                                                   const aLeft:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                                                                   const aRight:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                                                                   const aParent:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode=nil;
                                                                   const aColor:boolean=false);
begin
 inherited Create;
 fKey:=aKey;
 fValue:=aValue;
 fLeft:=aLeft;
 fRight:=aRight;
 fParent:=aParent;
 fColor:=aColor;
end;

destructor TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Destroy;
begin
 FreeAndNil(fLeft);
 FreeAndNil(fRight);
 inherited Destroy;
end;

procedure TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Clear;
begin
 fKey:=0;
 fLeft:=nil;
 fRight:=nil;
 fParent:=nil;
 fColor:=false;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Minimum:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=self;
 while assigned(result.fLeft) do begin
  result:=result.fLeft;
 end;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Maximum:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=self;
 while assigned(result.fRight) do begin
  result:=result.fRight;
 end;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Predecessor:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
var Last:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 if assigned(fLeft) then begin
  result:=fLeft;
  while assigned(result) and assigned(result.fRight) do begin
   result:=result.fRight;
  end;
 end else begin
  Last:=self;
  result:=Parent;
  while assigned(result) and (result.fLeft=Last) do begin
   Last:=result;
   result:=result.Parent;
  end;
 end;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Successor:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
var Last:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 if assigned(fRight) then begin
  result:=fRight;
  while assigned(result) and assigned(result.fLeft) do begin
   result:=result.fLeft;
  end;
 end else begin
  Last:=self;
  result:=Parent;
  while assigned(result) and (result.fRight=Last) do begin
   Last:=result;
   result:=result.Parent;
  end;
 end;
end;

constructor TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Create;
begin
 inherited Create;
 fRoot:=nil;
end;

destructor TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Destroy;
begin
 Clear;
 inherited Destroy;
end;

procedure TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Clear;
begin
 FreeAndNil(fRoot);
end;

procedure TpvVulkanDeviceMemoryChunkBlockRedBlackTree.RotateLeft(x:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
var y:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 y:=x.fRight;
 x.fRight:=y.fLeft;
 if assigned(y.fLeft) then begin
  y.fLeft.fParent:=x;
 end;
 y.fParent:=x.fParent;
 if x=fRoot then begin
  fRoot:=y;
 end else if x=x.fParent.fLeft then begin
  x.fparent.fLeft:=y;
 end else begin
  x.fParent.fRight:=y;
 end;
 y.fLeft:=x;
 x.fParent:=y;
end;

procedure TpvVulkanDeviceMemoryChunkBlockRedBlackTree.RotateRight(x:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
var y:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 y:=x.fLeft;
 x.fLeft:=y.fRight;
 if assigned(y.fRight) then begin
  y.fRight.fParent:=x;
 end;
 y.fParent:=x.fParent;
 if x=fRoot then begin
  fRoot:=y;
 end else if x=x.fParent.fRight then begin
  x.fParent.fRight:=y;
 end else begin
  x.fParent.fLeft:=y;
 end;
 y.fRight:=x;
 x.fParent:=y;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Find(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey):TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=fRoot;
 while assigned(result) do begin
  if aKey<result.fKey then begin
   result:=result.fLeft;
  end else if aKey>result.fKey then begin
   result:=result.fRight;
  end else begin
   exit;
  end;
 end;
 result:=nil;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Insert(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey;
                                                            const aValue:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeValue):TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
var x,y,xParentParent:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 x:=fRoot;
 y:=nil;
 while assigned(x) do begin
  y:=x;
  if aKey<x.fKey then begin
   x:=x.fLeft;
  end else begin
   x:=x.fRight;
  end;
 end;
 result:=TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode.Create(aKey,aValue,nil,nil,y,true);
 if assigned(y) then begin
  if aKey<y.fKey then begin
   y.Left:=result;
  end else begin
   y.Right:=result;
  end;
 end else begin
  fRoot:=result;
 end;
 x:=result;
 while (x<>fRoot) and assigned(x.fParent) and assigned(x.fParent.fParent) and x.fParent.fColor do begin
  xParentParent:=x.fParent.fParent;
  if x.fParent=xParentParent.fLeft then begin
   y:=xParentParent.fRight;
   if assigned(y) and y.fColor then begin
    x.fParent.fColor:=false;
    y.fColor:=false;
    xParentParent.fColor:=true;
    x:=xParentParent;
   end else begin
    if x=x.fParent.fRight then begin
     x:=x.fParent;
     RotateLeft(x);
    end;
    x.fParent.fColor:=false;
    xParentParent.fColor:=true;
    RotateRight(xParentParent);
   end;
  end else begin
   y:=xParentParent.fLeft;
   if assigned(y) and y.fColor then begin
    x.fParent.fColor:=false;
    y.fColor:=false;
    x.fParent.fParent.fColor:=true;
    x:=x.fParent.fParent;
   end else begin
    if x=x.fParent.fLeft then begin
     x:=x.fParent;
     RotateRight(x);
    end;
    x.fParent.fColor:=false;
    xParentParent.fColor:=true;
    RotateLeft(xParentParent);
   end;
  end;
 end;
 fRoot.fColor:=false;
end;

procedure TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Remove(const aNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode);
var w,x,y,z,xParent:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    TemporaryColor:boolean;
begin
 z:=aNode;
 y:=z;
 x:=nil;
 xParent:=nil;
 if assigned(x) and assigned(xParent) then begin
  // For to suppress "Value assigned to '*' never used" hints
 end;
 if assigned(y.fLeft) then begin
  if assigned(y.fRight) then begin
   y:=y.fRight;
   while assigned(y.fLeft) do begin
    y:=y.fLeft;
   end;
   x:=y.fRight;
  end else begin
   x:=y.fLeft;
  end;
 end else begin
  x:=y.fRight;
 end;
 if y<>z then begin
  z.fLeft.fParent:=y;
  y.fLeft:=z.fLeft;
  if y<>z.fRight then begin
   xParent:=y.fParent;
   if assigned(x) then begin
    x.fParent:=y.fParent;
   end;
   y.fParent.fLeft:=x;
   y.fRight:=z.fRight;
   z.fRight.fParent:=y;
  end else begin
   xParent:=y;
  end;
  if fRoot=z then begin
   fRoot:=y;
  end else if z.fParent.fLeft=z then begin
   z.fParent.fLeft:=y;
  end else begin
   z.fParent.fRight:=y;
  end;
  y.fParent:=z.fParent;
  TemporaryColor:=y.fColor;
  y.fColor:=z.fColor;
  z.fColor:=TemporaryColor;
  y:=z;
 end else begin
  xParent:=y.fParent;
  if assigned(x) then begin
   x.fParent:=y.fParent;
  end;
  if fRoot=z then begin
   fRoot:=x;
  end else if z.fParent.fLeft=z then begin
   z.fParent.fLeft:=x;
  end else begin
   z.fParent.fRight:=x;
  end;
 end;
 if assigned(y) then begin
  if not y.fColor then begin
   while (x<>fRoot) and not (assigned(x) and x.fColor) do begin
    if x=xParent.fLeft then begin
     w:=xParent.fRight;
     if w.fColor then begin
      w.fColor:=false;
      xParent.fColor:=true;
      RotateLeft(xParent);
      w:=xParent.fRight;
     end;
     if not ((assigned(w.fLeft) and w.fLeft.fColor) or (assigned(w.fRight) and w.fRight.fColor)) then begin
      w.fColor:=true;
      x:=xParent;
      xParent:=xParent.fParent;
     end else begin
      if not (assigned(w.fRight) and w.fRight.fColor) then begin
       w.fLeft.fColor:=false;
       w.fColor:=true;
       RotateRight(w);
       w:=xParent.fRight;
      end;
      w.fColor:=xParent.fColor;
      xParent.fColor:=false;
      if assigned(w.fRight) then begin
       w.fRight.fColor:=false;
      end;
      RotateLeft(xParent);
      x:=fRoot;
     end;
    end else begin
     w:=xParent.fLeft;
     if w.fColor then begin
      w.fColor:=false;
      xParent.fColor:=true;
      RotateRight(xParent);
      w:=xParent.fLeft;
     end;
     if not ((assigned(w.fLeft) and w.fLeft.fColor) or (assigned(w.fRight) and w.fRight.fColor)) then begin
      w.fColor:=true;
      x:=xParent;
      xParent:=xParent.fParent;
     end else begin
      if not (assigned(w.fLeft) and w.fLeft.fColor) then begin
       w.fRight.fColor:=false;
       w.fColor:=true;
       RotateLeft(w);
       w:=xParent.fLeft;
      end;
      w.fColor:=xParent.fColor;
      xParent.fColor:=false;
      if assigned(w.fLeft) then begin
       w.fLeft.fColor:=false;
      end;
      RotateRight(xParent);
      x:=fRoot;
     end;
    end;
   end;
   if assigned(x) then begin
    x.fColor:=false;
   end;
  end;
  y.Clear;
  y.Free;
 end;
end;

procedure TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Delete(const aKey:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeKey);
var Node:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 Node:=Find(aKey);
 if assigned(Node) then begin
  Remove(Node);
 end;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTree.LeftMost:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=fRoot;
 while assigned(result) and assigned(result.fLeft) do begin
  result:=result.fLeft;
 end;
end;

function TpvVulkanDeviceMemoryChunkBlockRedBlackTree.RightMost:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
begin
 result:=fRoot;
 while assigned(result) and assigned(result.fRight) do begin
  result:=result.fRight;
 end;
end;

constructor TpvVulkanDeviceMemoryChunkBlock.Create(const aMemoryChunk:TpvVulkanDeviceMemoryChunk;
                                                   const aOffset:TVkDeviceSize;
                                                   const aSize:TVkDeviceSize;
                                                   const aAllocationType:TpvVulkanDeviceMemoryAllocationType);
begin
 inherited Create;
 fMemoryChunk:=aMemoryChunk;
 fOffset:=aOffset;
 fSize:=aSize;
 fAllocationType:=aAllocationType;
 fOffsetRedBlackTreeNode:=fMemoryChunk.fOffsetRedBlackTree.Insert(aOffset,self);
 if fAllocationType=vdmatFree then begin
  fSizeRedBlackTreeNode:=fMemoryChunk.fSizeRedBlackTree.Insert(aSize,self);
 end;
end;

destructor TpvVulkanDeviceMemoryChunkBlock.Destroy;
begin
 fMemoryChunk.fOffsetRedBlackTree.Remove(fOffsetRedBlackTreeNode);
 if fAllocationType=vdmatFree then begin
  fMemoryChunk.fSizeRedBlackTree.Remove(fSizeRedBlackTreeNode);
 end;
 inherited Destroy;
end;

procedure TpvVulkanDeviceMemoryChunkBlock.Update(const aOffset:TVkDeviceSize;
                                                 const aSize:TVkDeviceSize;
                                                 const aAllocationType:TpvVulkanDeviceMemoryAllocationType);
begin
 if fOffset<>aOffset then begin
  fMemoryChunk.fOffsetRedBlackTree.Remove(fOffsetRedBlackTreeNode);
  fOffsetRedBlackTreeNode:=fMemoryChunk.fOffsetRedBlackTree.Insert(aOffset,self);
 end;
 if ((fAllocationType=vdmatFree)<>(aAllocationType=vdmatFree)) or (fSize<>aSize) then begin
  if fAllocationType=vdmatFree then begin
   fMemoryChunk.fSizeRedBlackTree.Remove(fSizeRedBlackTreeNode);
  end;
  if aAllocationType=vdmatFree then begin
   fSizeRedBlackTreeNode:=fMemoryChunk.fSizeRedBlackTree.Insert(aSize,self);
  end;
 end;
 fOffset:=aOffset;
 fSize:=aSize;
 fAllocationType:=aAllocationType;
 inherited Destroy;
end;

constructor TpvVulkanDeviceMemoryChunk.Create(const aMemoryManager:TpvVulkanDeviceMemoryManager;
                                              const aMemoryChunkFlags:TpvVulkanDeviceMemoryChunkFlags;
                                              const aSize:TVkDeviceSize;
                                              const aSizeIsMinimumSize:boolean;
                                              const aMemoryTypeBits:TpvUInt32;
                                              const aMemoryRequiredPropertyFlags:TVkMemoryPropertyFlags;
                                              const aMemoryPreferredPropertyFlags:TVkMemoryPropertyFlags;
                                              const aMemoryAvoidPropertyFlags:TVkMemoryPropertyFlags;
                                              const aMemoryRequiredHeapFlags:TVkMemoryHeapFlags;
                                              const aMemoryPreferredHeapFlags:TVkMemoryHeapFlags;
                                              const aMemoryAvoidHeapFlags:TVkMemoryHeapFlags;
                                              const aMemoryChunkList:PpvVulkanDeviceMemoryManagerChunkList);
type TBlacklistedHeaps=array of TpvUInt32;
var Index,HeapIndex,CurrentScore,BestScore,CountBlacklistedHeaps,BlacklistedHeapIndex:TpvInt32;
    MemoryAllocateInfo:TVkMemoryAllocateInfo;
    PhysicalDevice:TpvVulkanPhysicalDevice;
    CurrentSize,BestSize,CurrentWantedChunkSize,BestWantedChunkSize:TVkDeviceSize;
    Found,OK:boolean;
    ResultCode,LastResultCode:TVkResult;
    BlacklistedHeaps:TBlacklistedHeaps;
begin
 inherited Create;

 fMemoryManager:=aMemoryManager;

 fMemoryChunkFlags:=aMemoryChunkFlags;

 fSize:=aSize;

 fMemoryChunkList:=aMemoryChunkList;

 fUsed:=0;

 fMappedOffset:=0;

 fMappedSize:=fSize;

 fMemoryHandle:=VK_NULL_HANDLE;

 fMemory:=nil;

 LastResultCode:=VK_SUCCESS;

 BlacklistedHeaps:=nil;
 CountBlacklistedHeaps:=0;
 try

  repeat

   fMemoryTypeIndex:=0;
   fMemoryTypeBits:=0;
   fMemoryHeapIndex:=0;
   PhysicalDevice:=fMemoryManager.fDevice.fPhysicalDevice;
   BestSize:=0;
   BestScore:=-1;
   BestWantedChunkSize:=aSize;
   Found:=false;
   for Index:=0 to length(PhysicalDevice.fMemoryProperties.memoryTypes)-1 do begin
    if ((aMemoryTypeBits and (TpvUInt32(1) shl Index))<>0) and
       ((PhysicalDevice.fMemoryProperties.memoryTypes[Index].propertyFlags and aMemoryRequiredPropertyFlags)=aMemoryRequiredPropertyFlags) and
       ((aMemoryAvoidPropertyFlags=0) or ((PhysicalDevice.fMemoryProperties.memoryTypes[Index].propertyFlags and aMemoryAvoidPropertyFlags)=0)) then begin
     HeapIndex:=PhysicalDevice.fMemoryProperties.memoryTypes[Index].heapIndex;
     CurrentSize:=PhysicalDevice.fMemoryProperties.memoryHeaps[HeapIndex].size;
     if aSizeIsMinimumSize then begin
{$ifdef Android}
      if aSize<VulkanDefaultAndroidHeapChunkSize then begin
       CurrentWantedChunkSize:=VulkanDefaultAndroidHeapChunkSize;
      end else begin
       CurrentWantedChunkSize:=aSize;
      end;
{$else}
      if CurrentSize<=VulkanSmallMaximumHeapSize then begin
       if aSize<VulkanDefaultSmallHeapChunkSize then begin
        CurrentWantedChunkSize:=VulkanDefaultSmallHeapChunkSize;
       end else begin
        CurrentWantedChunkSize:=aSize;
       end;
      end else begin
       if aSize<VulkanDefaultLargeHeapChunkSize then begin
        CurrentWantedChunkSize:=VulkanDefaultLargeHeapChunkSize;
       end else begin
        CurrentWantedChunkSize:=aSize;
       end;
      end;
{$endif}
     end else begin
      CurrentWantedChunkSize:=aSize;
     end;
     if ((PhysicalDevice.fMemoryProperties.memoryHeaps[HeapIndex].flags and aMemoryRequiredHeapFlags)=aMemoryRequiredHeapFlags) and
        ((aMemoryAvoidHeapFlags=0) or ((PhysicalDevice.fMemoryProperties.memoryHeaps[HeapIndex].flags and aMemoryAvoidHeapFlags)=0)) and
        (CurrentWantedChunkSize<=CurrentSize) and (BestSize<CurrentSize) then begin
      CurrentScore:=0;
      if (PhysicalDevice.fMemoryProperties.memoryTypes[Index].propertyFlags and aMemoryPreferredPropertyFlags)=aMemoryPreferredPropertyFlags then begin
       CurrentScore:=CurrentScore or 2;
      end;
      if (PhysicalDevice.fMemoryProperties.memoryHeaps[HeapIndex].flags and aMemoryPreferredHeapFlags)=aMemoryPreferredHeapFlags then begin
       CurrentScore:=CurrentScore or 1;
      end;
      if BestScore<CurrentScore then begin
       OK:=true;
       for BlacklistedHeapIndex:=0 to CountBlacklistedHeaps-1 do begin
        if BlacklistedHeaps[BlacklistedHeapIndex]=PhysicalDevice.fMemoryProperties.memoryTypes[Index].heapIndex then begin
         OK:=false;
         break;
        end;
       end;
       if OK then begin
        BestScore:=CurrentScore;
        BestSize:=CurrentSize;
        BestWantedChunkSize:=CurrentWantedChunkSize;
        fMemoryTypeIndex:=Index;
        fMemoryTypeBits:=TpvUInt32(1) shl Index;
        fMemoryHeapIndex:=PhysicalDevice.fMemoryProperties.memoryTypes[Index].heapIndex;
        Found:=true;
       end;
      end;
     end;
    end;
   end;
   if not Found then begin
    if LastResultCode<>VK_SUCCESS then begin
     HandleResultCode(LastResultCode);
    end;
    raise EpvVulkanException.Create('No suitable device memory heap available');
   end;

   fMemoryPropertyFlags:=PhysicalDevice.fMemoryProperties.memoryTypes[fMemoryTypeIndex].propertyFlags;

   fMemoryHeapFlags:=PhysicalDevice.fMemoryProperties.memoryHeaps[fMemoryHeapIndex].flags;

   FillChar(MemoryAllocateInfo,SizeOf(TVkMemoryAllocateInfo),#0);
   MemoryAllocateInfo.sType:=VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
   MemoryAllocateInfo.pNext:=nil;
   MemoryAllocateInfo.allocationSize:=BestWantedChunkSize;
   MemoryAllocateInfo.memoryTypeIndex:=fMemoryTypeIndex;

   ResultCode:=fMemoryManager.fDevice.Commands.AllocateMemory(fMemoryManager.fDevice.fDeviceHandle,@MemoryAllocateInfo,fMemoryManager.fDevice.fAllocationCallbacks,@fMemoryHandle);

   case ResultCode of
    VK_ERROR_FRAGMENTED_POOL,
    VK_ERROR_OUT_OF_HOST_MEMORY,
    VK_ERROR_OUT_OF_DEVICE_MEMORY:begin
     LastResultCode:=ResultCode;
     if length(BlacklistedHeaps)<(CountBlacklistedHeaps+1) then begin
      SetLength(BlacklistedHeaps,(CountBlacklistedHeaps+1)*2);
     end;
     BlacklistedHeaps[CountBlacklistedHeaps]:=fMemoryHeapIndex;
     inc(CountBlacklistedHeaps);
     continue;
    end;
    else begin
     HandleResultCode(ResultCode);
     break;
    end;
   end;

  until false;

 finally
  BlacklistedHeaps:=nil;
 end;

 fOffsetRedBlackTree:=TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Create;
 fSizeRedBlackTree:=TpvVulkanDeviceMemoryChunkBlockRedBlackTree.Create;

 TpvVulkanDeviceMemoryChunkBlock.Create(self,0,BestWantedChunkSize,vdmatFree);

 fLock:=TCriticalSection.Create;

 if assigned(fMemoryChunkList^.First) then begin
  fMemoryChunkList^.First.fPreviousMemoryChunk:=self;
  fNextMemoryChunk:=fMemoryChunkList^.First;
 end else begin
  fMemoryChunkList^.Last:=self;
  fNextMemoryChunk:=nil;
 end;
 fMemoryChunkList^.First:=self;
 fPreviousMemoryChunk:=nil;

 if vdmcfPersistentMapped in fMemoryChunkFlags then begin
  fLock.Acquire;
  try
   if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
    if assigned(fMemory) then begin
     raise EpvVulkanException.Create('Memory is already mapped');
    end else begin
     fMappedOffset:=0;
     fMappedSize:=BestWantedChunkSize;
     HandleResultCode(fMemoryManager.fDevice.Commands.MapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle,0,aSize,0,@fMemory));
    end;
   end else begin
    raise EpvVulkanException.Create('Memory can''t mapped');
   end;
  finally
   fLock.Release;
  end;
 end;

 fSize:=BestWantedChunkSize;

end;

destructor TpvVulkanDeviceMemoryChunk.Destroy;
begin

 if (vdmcfPersistentMapped in fMemoryChunkFlags) and
    assigned(fMemory) and
    ((fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0) then begin
  fLock.Acquire;
  try
   fMemoryManager.fDevice.Commands.UnmapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle);
   fMemory:=nil;
  finally
   fLock.Release;
  end;
 end;

 if assigned(fOffsetRedBlackTree) then begin
  while assigned(fOffsetRedBlackTree.fRoot) do begin
   fOffsetRedBlackTree.fRoot.fValue.Free;
  end;
 end;

 if assigned(fPreviousMemoryChunk) then begin
  fPreviousMemoryChunk.fNextMemoryChunk:=fNextMemoryChunk;
 end else if fMemoryChunkList^.First=self then begin
  fMemoryChunkList^.First:=fNextMemoryChunk;
 end;
 if assigned(fNextMemoryChunk) then begin
  fNextMemoryChunk.fPreviousMemoryChunk:=fPreviousMemoryChunk;
 end else if fMemoryChunkList^.Last=self then begin
  fMemoryChunkList^.Last:=fPreviousMemoryChunk;
 end;

 if fMemoryHandle<>VK_NULL_HANDLE then begin
  if ((fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0) and assigned(fMemory) then begin
   fMemoryManager.fDevice.Commands.UnmapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle);
   fMemory:=nil;
  end;
  fMemoryManager.fDevice.Commands.FreeMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle,fMemoryManager.fDevice.fAllocationCallbacks);
 end;

 fOffsetRedBlackTree.Free;
 fSizeRedBlackTree.Free;

 FreeAndNil(fLock);

 fMemoryHandle:=VK_NULL_HANDLE;

 inherited Destroy;
end;

function TpvVulkanDeviceMemoryChunk.AllocateMemory(out aOffset:TVkDeviceSize;const aSize,aAlignment:TVkDeviceSize;const aAllocationType:TpvVulkanDeviceMemoryAllocationType):boolean;
var Node,OtherNode,LastNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    MemoryChunkBlock:TpvVulkanDeviceMemoryChunkBlock;
    Alignment,Offset,MemoryChunkBlockBeginOffset,MemoryChunkBlockEndOffset,PayloadBeginOffset,PayloadEndOffset,
    BufferImageGranularity,BufferImageGranularityInvertedMask:TVkDeviceSize;
    Direction:TpvInt32;
    TryAgain:boolean;
begin
 result:=false;

 if aSize>0 then begin

  Alignment:=Max(1,VulkanDeviceSizeRoundUpToPowerOfTwo(aAlignment));

  BufferImageGranularity:=Max(1,VulkanDeviceSizeRoundUpToPowerOfTwo(MemoryManager.fDevice.fPhysicalDevice.fProperties.limits.bufferImageGranularity));

  BufferImageGranularityInvertedMask:=not (BufferImageGranularity-1);

  fLock.Acquire;
  try

   // Best-fit search
   Node:=fSizeRedBlackTree.fRoot;
   while assigned(Node) do begin
    if aSize<Node.fKey then begin
     if assigned(Node.fLeft) then begin
      // If free block is too big, then go to left
      Node:=Node.fLeft;
      continue;
     end else begin
      // If free block is too big and there is no left children node, then try to find suitable smaller but not too small free blocks
      while assigned(Node) and (Node.fKey>aSize) do begin
       OtherNode:=Node.Predecessor;
       if assigned(OtherNode) and (OtherNode.fKey>=aSize) then begin
        Node:=OtherNode;
       end else begin
        break;
       end;
      end;
      break;
     end;
    end else if aSize>Node.fKey then begin
     if assigned(Node.fRight) then begin
      // If free block is too small, go to right
      Node:=Node.fRight;
      continue;
     end else begin
      // If free block is too small and there is no right children node, then try to find suitable bigger but not too small free blocks
      while assigned(Node) and (Node.fKey<aSize) do begin
       OtherNode:=Node.Successor;
       if assigned(OtherNode) then begin
        Node:=OtherNode;
       end else begin
        break;
       end;
      end;
      break;
     end;
    end else begin
     // Perfect match
     break;
    end;
   end;

   LastNode:=nil;

   repeat

    TryAgain:=false;

    // Check block for if it fits to the desired alignment, otherwise search for a better suitable block
    if Alignment>1 then begin
     while assigned(Node) and (Node.fKey>=aSize) do begin
      MemoryChunkBlock:=Node.fValue;
      if ((MemoryChunkBlock.Offset and (Alignment-1))<>0) and
         ((MemoryChunkBlock.Offset+(Alignment-(MemoryChunkBlock.Offset and (Alignment-1)))+aSize)>=(MemoryChunkBlock.Offset+MemoryChunkBlock.Size)) then begin
       // If free block is alignment-technical too small, then try to find with-alignment-technical suitable bigger blocks
       LastNode:=nil;
       Node:=Node.Successor;
      end else begin
       break;
      end;
     end;
    end;

    // Check block for BufferImageGranularity satisfaction
    if (BufferImageGranularity>1) and
      assigned(Node) and
      assigned(Node.fValue) then begin

     MemoryChunkBlock:=Node.fValue;

     MemoryChunkBlockBeginOffset:=MemoryChunkBlock.Offset;

     PayloadBeginOffset:=MemoryChunkBlockBeginOffset;
     if (Alignment>1) and ((PayloadBeginOffset and (Alignment-1))<>0) then begin
      inc(PayloadBeginOffset,Alignment-(PayloadBeginOffset and (Alignment-1)));
     end;

     PayloadEndOffset:=PayloadBeginOffset+aSize;

     OtherNode:=Node.fValue.fOffsetRedBlackTreeNode.Predecessor;
     if assigned(OtherNode) and
        assigned(OtherNode.fValue) and
        ((OtherNode.fValue.fAllocationType<>vdmatFree) and
         (((OtherNode.fValue.fAllocationType in [vdmatUnknown,vdmatBuffer])<>(aAllocationType in [vdmatUnknown,vdmatBuffer])) or
          ((OtherNode.fValue.fAllocationType in [vdmatImageLinear,vdmatImageOptimal])<>(aAllocationType in [vdmatImageLinear,vdmatImageOptimal])))) then begin
      if (PayloadBeginOffset and BufferImageGranularityInvertedMask)=((OtherNode.fValue.fOffset+(OtherNode.fValue.fSize-1)) and BufferImageGranularityInvertedMask) then begin
       if LastNode=Node then begin
        LastNode:=nil;
        Node:=Node.Successor;
       end else begin
        LastNode:=Node;
        if Alignment<BufferImageGranularity then begin
         Alignment:=BufferImageGranularity;
        end;
       end;
       TryAgain:=true;
      end;
     end;

     if not TryAgain then begin
      OtherNode:=Node.fValue.fOffsetRedBlackTreeNode.Successor;
      if assigned(OtherNode) and
         assigned(OtherNode.fValue) and
         ((OtherNode.fValue.fAllocationType<>vdmatFree) and
          (((OtherNode.fValue.fAllocationType in [vdmatUnknown,vdmatBuffer])<>(aAllocationType in [vdmatUnknown,vdmatBuffer])) or
           ((OtherNode.fValue.fAllocationType in [vdmatImageLinear,vdmatImageOptimal])<>(aAllocationType in [vdmatImageLinear,vdmatImageOptimal])))) then begin
       if ((PayloadEndOffset-1) and BufferImageGranularityInvertedMask)=(OtherNode.fValue.fOffset and BufferImageGranularityInvertedMask) then begin
        LastNode:=nil;
        Node:=Node.Successor;
        TryAgain:=true;
       end;
      end;
     end;

    end;

   until not TryAgain;

   if assigned(Node) and (Node.fKey>=aSize) then begin

    MemoryChunkBlock:=Node.fValue;

    MemoryChunkBlockBeginOffset:=MemoryChunkBlock.Offset;

    MemoryChunkBlockEndOffset:=MemoryChunkBlockBeginOffset+MemoryChunkBlock.Size;

    PayloadBeginOffset:=MemoryChunkBlockBeginOffset;
    if (Alignment>1) and ((PayloadBeginOffset and (Alignment-1))<>0) then begin
     inc(PayloadBeginOffset,Alignment-(PayloadBeginOffset and (Alignment-1)));
    end;

    PayloadEndOffset:=PayloadBeginOffset+aSize;

    if (PayloadBeginOffset<PayloadEndOffset) and
       (PayloadEndOffset<=MemoryChunkBlockEndOffset) then begin

     MemoryChunkBlock.Update(PayloadBeginOffset,PayloadEndOffset-PayloadBeginOffset,aAllocationType);

     if MemoryChunkBlockBeginOffset<PayloadBeginOffset then begin
      TpvVulkanDeviceMemoryChunkBlock.Create(self,MemoryChunkBlockBeginOffset,PayloadBeginOffset-MemoryChunkBlockBeginOffset,vdmatFree);
     end;

     if PayloadEndOffset<MemoryChunkBlockEndOffset then begin
      TpvVulkanDeviceMemoryChunkBlock.Create(self,PayloadEndOffset,MemoryChunkBlockEndOffset-PayloadEndOffset,vdmatFree);
     end;

     aOffset:=PayloadBeginOffset;

     inc(fUsed,PayloadEndOffset-PayloadBeginOffset);

     result:=true;

    end;

   end;

  finally
   fLock.Release;
  end;

 end;

end;

function TpvVulkanDeviceMemoryChunk.ReallocateMemory(var aOffset:TVkDeviceSize;const aSize,aAlignment:TVkDeviceSize):boolean;
var Node,OtherNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    MemoryChunkBlock,OtherMemoryChunkBlock:TpvVulkanDeviceMemoryChunkBlock;
    TempOffset,TempSize:TVkDeviceSize;
begin
 result:=false;

 fLock.Acquire;
 try

  Node:=fOffsetRedBlackTree.Find(aOffset);
  if assigned(Node) then begin
   MemoryChunkBlock:=Node.fValue;
   if MemoryChunkBlock.fAllocationType<>vdmatFree then begin
    dec(fUsed,MemoryChunkBlock.Size);
    if aSize=0 then begin
     result:=FreeMemory(aOffset);
    end else if MemoryChunkBlock.fSize=aSize then begin
     result:=true;
    end else begin
     if MemoryChunkBlock.fSize<aSize then begin
      OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Successor;
      if assigned(OtherNode) and
         (MemoryChunkBlock.fOffsetRedBlackTreeNode<>OtherNode) then begin
       OtherMemoryChunkBlock:=OtherNode.fValue;
       if OtherMemoryChunkBlock.fAllocationType=vdmatFree then begin
        if (MemoryChunkBlock.fOffset+aSize)<(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize) then begin
         MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,aSize,MemoryChunkBlock.fAllocationType);
         OtherMemoryChunkBlock.Update(MemoryChunkBlock.fOffset+aSize,(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize)-(MemoryChunkBlock.fOffset+aSize),vdmatFree);
         result:=true;
        end else if (MemoryChunkBlock.fOffset+aSize)=(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize) then begin
         MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,aSize,MemoryChunkBlock.fAllocationType);
         OtherMemoryChunkBlock.Free;
         result:=true;
        end;
       end;
      end;
     end else if MemoryChunkBlock.fSize>aSize then begin
      OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Successor;
      if assigned(OtherNode) and
         (MemoryChunkBlock.fOffsetRedBlackTreeNode<>OtherNode) and
         (OtherNode.fValue.fAllocationType=vdmatFree) then begin
       OtherMemoryChunkBlock:=OtherNode.fValue;
       TempOffset:=MemoryChunkBlock.fOffset+aSize;
       TempSize:=(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize)-TempOffset;
       MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,aSize,MemoryChunkBlock.fAllocationType);
       OtherMemoryChunkBlock.Update(TempOffset,TempSize,vdmatFree);
       result:=true;
      end else begin
       TempOffset:=MemoryChunkBlock.fOffset+aSize;
       TempSize:=(MemoryChunkBlock.fOffset+MemoryChunkBlock.fSize)-TempOffset;
       MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,aSize,MemoryChunkBlock.fAllocationType);
       TpvVulkanDeviceMemoryChunkBlock.Create(self,TempOffset,TempSize,vdmatFree);
       result:=true;
      end;
     end;
    end;
    if result then begin
     inc(fUsed,aSize);
    end;
   end;
  end;

 finally
  fLock.Release;
 end;

end;

function TpvVulkanDeviceMemoryChunk.FreeMemory(const aOffset:TVkDeviceSize):boolean;
var Node,OtherNode:TpvVulkanDeviceMemoryChunkBlockRedBlackTreeNode;
    MemoryChunkBlock,OtherMemoryChunkBlock:TpvVulkanDeviceMemoryChunkBlock;
    TempOffset,TempSize:TVkDeviceSize;
begin
 result:=false;

 fLock.Acquire;
 try

  Node:=fOffsetRedBlackTree.Find(aOffset);
  if assigned(Node) then begin

   MemoryChunkBlock:=Node.fValue;
   if MemoryChunkBlock.fAllocationType<>vdmatFree then begin

    dec(fUsed,MemoryChunkBlock.fSize);

    // Freeing including coalescing free blocks
    while assigned(Node) do begin

     // Coalescing previous free block with current block
     OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Predecessor;
     if assigned(OtherNode) and (OtherNode.fValue.fAllocationType=vdmatFree) then begin
      OtherMemoryChunkBlock:=OtherNode.fValue;
      TempOffset:=OtherMemoryChunkBlock.fOffset;
      TempSize:=(MemoryChunkBlock.fOffset+MemoryChunkBlock.fSize)-TempOffset;
      MemoryChunkBlock.Free;
      OtherMemoryChunkBlock.Update(TempOffset,TempSize,vdmatFree);
      MemoryChunkBlock:=OtherMemoryChunkBlock;
      Node:=OtherNode;
      continue;
     end;

     // Coalescing current block with next free block
     OtherNode:=MemoryChunkBlock.fOffsetRedBlackTreeNode.Successor;
     if assigned(OtherNode) and (OtherNode.fValue.fAllocationType=vdmatFree) then begin
      OtherMemoryChunkBlock:=OtherNode.fValue;
      TempOffset:=MemoryChunkBlock.fOffset;
      TempSize:=(OtherMemoryChunkBlock.fOffset+OtherMemoryChunkBlock.fSize)-TempOffset;
      OtherMemoryChunkBlock.Free;
      MemoryChunkBlock.Update(TempOffset,TempSize,vdmatFree);
      continue;
     end;

     if MemoryChunkBlock.fAllocationType<>vdmatFree then begin
      // Mark block as free
      MemoryChunkBlock.Update(MemoryChunkBlock.fOffset,MemoryChunkBlock.fSize,vdmatFree);
     end;
     break;

    end;

    result:=true;
    
   end;

  end;

 finally
  fLock.Release;
 end;
end;

function TpvVulkanDeviceMemoryChunk.MapMemory(const aOffset:TVkDeviceSize=0;const aSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
begin
 result:=nil;
 if vdmcfPersistentMapped in fMemoryChunkFlags then begin
  if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
   if assigned(fMemory) then begin
    result:=TpvPointer(TpvPtrUInt(TpvPtrUInt(fMemory)+TpvPtrUInt(aOffset)));
   end else begin
    raise EpvVulkanException.Create('Persistent mapped memory is not mapped?');
   end;
  end else begin
   raise EpvVulkanException.Create('Memory can''t mapped');
  end;
 end else begin
  fLock.Acquire;
  try
   if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
    if assigned(fMemory) then begin
     raise EpvVulkanException.Create('Memory is already mapped');
    end else begin
     fMappedOffset:=aOffset;
     fMappedSize:=aSize;
     HandleResultCode(fMemoryManager.fDevice.Commands.MapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle,aOffset,aSize,0,@result));
     fMemory:=result;
    end;
   end else begin
    raise EpvVulkanException.Create('Memory can''t mapped');
   end;
  finally
   fLock.Release;
  end;
 end;
end;

procedure TpvVulkanDeviceMemoryChunk.UnmapMemory;
begin
 if vdmcfPersistentMapped in fMemoryChunkFlags then begin
  if assigned(fMemory) then begin
   // Do nothing in this case
  end else begin 
   raise EpvVulkanException.Create('Persistent mapped memory is not mapped?');
  end;
 end else begin
  fLock.Acquire;
  try
   if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
    if assigned(fMemory) then begin
     fMemoryManager.fDevice.Commands.UnmapMemory(fMemoryManager.fDevice.fDeviceHandle,fMemoryHandle);
     fMemory:=nil;
    end else begin
     raise EpvVulkanException.Create('Non-mapped memory can''t unmapped');
    end;
   end;
  finally
   fLock.Release;
  end;
 end;
end;

procedure TpvVulkanDeviceMemoryChunk.FlushMappedMemory;
var MappedMemoryRange:TVkMappedMemoryRange;
begin
 fLock.Acquire;
 try
  if assigned(fMemory) then begin
   FillChar(MappedMemoryRange,SizeOf(TVkMappedMemoryRange),#0);
   MappedMemoryRange.sType:=VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
   MappedMemoryRange.pNext:=nil;
   MappedMemoryRange.memory:=fMemoryHandle;
   MappedMemoryRange.offset:=fMappedOffset;
   MappedMemoryRange.size:=fMappedSize;
   HandleResultCode(vkFlushMappedMemoryRanges(fMemoryManager.fDevice.fDeviceHandle,1,@MappedMemoryRange));
  end else begin
   raise EpvVulkanException.Create('Non-mapped memory can''t be flushed');
  end;
 finally
  fLock.Release;
 end;
end;

procedure TpvVulkanDeviceMemoryChunk.FlushMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
var MappedMemoryRange:TVkMappedMemoryRange;
    Offset,Size:TVkDeviceSize;
begin
 fLock.Acquire;
 try
  if assigned(fMemory) then begin
   Offset:=fMappedOffset+TVkDeviceSize(TpvPtrUInt(aBase)-TpvPtrUInt(fMemory));
   if aSize=TVkDeviceSize(VK_WHOLE_SIZE) then begin
    Size:=TpvInt64(Max(0,TpvInt64((fMappedOffset+fMappedSize)-Offset)));
   end else begin
    Size:=Min(TpvInt64(Max(TpvInt64(aSize),0)),TpvInt64(Max(0,TpvInt64((fMappedOffset+fMappedSize)-Offset))));
   end;
   FillChar(MappedMemoryRange,SizeOf(TVkMappedMemoryRange),#0);
   MappedMemoryRange.sType:=VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
   MappedMemoryRange.pNext:=nil;
   MappedMemoryRange.memory:=fMemoryHandle;
   MappedMemoryRange.offset:=Offset;
   MappedMemoryRange.size:=Size;
   HandleResultCode(vkFlushMappedMemoryRanges(fMemoryManager.fDevice.fDeviceHandle,1,@MappedMemoryRange));
  end else begin
   raise EpvVulkanException.Create('Non-mapped memory can''t be flushed');
  end;
 finally
  fLock.Release;
 end;
end;

procedure TpvVulkanDeviceMemoryChunk.InvalidateMappedMemory;
var MappedMemoryRange:TVkMappedMemoryRange;
begin
 fLock.Acquire;
 try
  if assigned(fMemory) then begin
   FillChar(MappedMemoryRange,SizeOf(TVkMappedMemoryRange),#0);
   MappedMemoryRange.sType:=VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
   MappedMemoryRange.pNext:=nil;
   MappedMemoryRange.memory:=fMemoryHandle;
   MappedMemoryRange.offset:=fMappedOffset;
   MappedMemoryRange.size:=fMappedSize;
   HandleResultCode(vkInvalidateMappedMemoryRanges(fMemoryManager.fDevice.fDeviceHandle,1,@MappedMemoryRange));
  end else begin
   raise EpvVulkanException.Create('Non-mapped memory can''t be invalidated');
  end;
 finally
  fLock.Release;
 end;
end;

procedure TpvVulkanDeviceMemoryChunk.InvalidateMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
var MappedMemoryRange:TVkMappedMemoryRange;
    Offset,Size:TVkDeviceSize;
begin
 fLock.Acquire;
 try
  if assigned(fMemory) then begin
   Offset:=fMappedOffset+TVkDeviceSize(TpvPtrUInt(aBase)-TpvPtrUInt(fMemory));
   if aSize=TVkDeviceSize(VK_WHOLE_SIZE) then begin
    Size:=TpvInt64(Max(0,TpvInt64((fMappedOffset+fMappedSize)-Offset)));
   end else begin
    Size:=Min(TpvInt64(Max(TpvInt64(aSize),0)),TpvInt64(Max(0,TpvInt64((fMappedOffset+fMappedSize)-Offset))));
   end;
   FillChar(MappedMemoryRange,SizeOf(TVkMappedMemoryRange),#0);
   MappedMemoryRange.sType:=VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE;
   MappedMemoryRange.pNext:=nil;
   MappedMemoryRange.memory:=fMemoryHandle;
   MappedMemoryRange.offset:=Offset;
   MappedMemoryRange.size:=Size;
   HandleResultCode(vkInvalidateMappedMemoryRanges(fMemoryManager.fDevice.fDeviceHandle,1,@MappedMemoryRange));
  end else begin
   raise EpvVulkanException.Create('Non-mapped memory can''t be invalidated');
  end;
 finally
  fLock.Release;
 end;
end;

constructor TpvVulkanDeviceMemoryBlock.Create(const aMemoryManager:TpvVulkanDeviceMemoryManager;
                                              const aMemoryChunk:TpvVulkanDeviceMemoryChunk;
                                              const aOffset:TVkDeviceSize;
                                              const aSize:TVkDeviceSize);
begin

 inherited Create;

 fMemoryManager:=aMemoryManager;

 fMemoryChunk:=aMemoryChunk;

 fOffset:=aOffset;

 fSize:=aSize;

 if assigned(fMemoryManager.fLastMemoryBlock) then begin
  fMemoryManager.fLastMemoryBlock.fNextMemoryBlock:=self;
  fPreviousMemoryBlock:=fMemoryManager.fLastMemoryBlock;
 end else begin
  fMemoryManager.fFirstMemoryBlock:=self;
  fPreviousMemoryBlock:=nil;
 end;
 fMemoryManager.fLastMemoryBlock:=self;
 fNextMemoryBlock:=nil;

end;

destructor TpvVulkanDeviceMemoryBlock.Destroy;
begin
 if assigned(fPreviousMemoryBlock) then begin
  fPreviousMemoryBlock.fNextMemoryBlock:=fNextMemoryBlock;
 end else if fMemoryManager.fFirstMemoryBlock=self then begin
  fMemoryManager.fFirstMemoryBlock:=fNextMemoryBlock;
 end;
 if assigned(fNextMemoryBlock) then begin
  fNextMemoryBlock.fPreviousMemoryBlock:=fPreviousMemoryBlock;
 end else if fMemoryManager.fLastMemoryBlock=self then begin
  fMemoryManager.fLastMemoryBlock:=fPreviousMemoryBlock;
 end;
 inherited Destroy;
end;

function TpvVulkanDeviceMemoryBlock.MapMemory(const aOffset:TVkDeviceSize=0;const aSize:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE)):PVkVoid;
var Offset,Size:TVkDeviceSize;
begin
 Offset:=fOffset+aOffset;
 if aSize=TVkDeviceSize(VK_WHOLE_SIZE) then begin
  Size:=TpvInt64(Max(0,TpvInt64((fOffset+fSize)-Offset)));
 end else begin
  Size:=Min(TpvInt64(Max(TpvInt64(aSize),0)),TpvInt64(Max(0,TpvInt64((fOffset+fSize)-Offset))));
 end;
 result:=fMemoryChunk.MapMemory(Offset,Size);
end;

procedure TpvVulkanDeviceMemoryBlock.UnmapMemory;
begin
 fMemoryChunk.UnmapMemory;
end;

procedure TpvVulkanDeviceMemoryBlock.FlushMappedMemory;
begin
 fMemoryChunk.FlushMappedMemory;
end;

procedure TpvVulkanDeviceMemoryBlock.FlushMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
begin
 fMemoryChunk.FlushMappedMemoryRange(aBase,aSize);
end;

procedure TpvVulkanDeviceMemoryBlock.InvalidateMappedMemory;
begin
 fMemoryChunk.InvalidateMappedMemory;
end;

procedure TpvVulkanDeviceMemoryBlock.InvalidateMappedMemoryRange(const aBase:TpvPointer;const aSize:TVkDeviceSize);
begin
 fMemoryChunk.InvalidateMappedMemoryRange(aBase,aSize);
end;

function TpvVulkanDeviceMemoryBlock.Fill(const aData:PVkVoid;const aSize:TVkDeviceSize):TVkDeviceSize;
var Memory:PVkVoid;
begin
 if aSize<=0 then begin
  result:=0;
 end else if aSize>fSize then begin
  result:=fSize;
 end else begin
  result:=aSize;
 end;
 Memory:=MapMemory;
 try
  Move(aData^,Memory^,result);
 finally
  UnmapMemory;
 end;
end;

constructor TpvVulkanDeviceMemoryManager.Create(const aDevice:TpvVulkanDevice);
begin
 inherited Create;

 fDevice:=aDevice;

 fLock:=TCriticalSection.Create;

 FillChar(fMemoryChunkList,SizeOf(TpvVulkanDeviceMemoryManagerChunkList),#0);

 fFirstMemoryBlock:=nil;
 fLastMemoryBlock:=nil;

end;

destructor TpvVulkanDeviceMemoryManager.Destroy;
var Index:TpvInt32;
begin
 while assigned(fFirstMemoryBlock) do begin
  fFirstMemoryBlock.Free;
 end;
 while assigned(fMemoryChunkList.First) do begin
  fMemoryChunkList.First.Free;
 end;
 fLock.Free;
 inherited Destroy;
end;

function TpvVulkanDeviceMemoryManager.AllocateMemoryBlock(const aMemoryBlockFlags:TpvVulkanDeviceMemoryBlockFlags;
                                                          const aMemoryBlockSize:TVkDeviceSize;
                                                          const aMemoryBlockAlignment:TVkDeviceSize;
                                                          const aMemoryTypeBits:TpvUInt32;
                                                          const aMemoryRequiredPropertyFlags:TVkMemoryPropertyFlags;
                                                          const aMemoryPreferredPropertyFlags:TVkMemoryPropertyFlags;
                                                          const aMemoryAvoidPropertyFlags:TVkMemoryPropertyFlags;
                                                          const aMemoryRequiredHeapFlags:TVkMemoryHeapFlags;
                                                          const aMemoryPreferredHeapFlags:TVkMemoryHeapFlags;
                                                          const aMemoryAvoidHeapFlags:TVkMemoryHeapFlags;
                                                          const aMemoryAllocationType:TpvVulkanDeviceMemoryAllocationType):TpvVulkanDeviceMemoryBlock;
var TryIteration:TpvInt32;
    MemoryChunk:TpvVulkanDeviceMemoryChunk;
    Offset,Alignment:TVkDeviceSize;
    MemoryChunkFlags:TpvVulkanDeviceMemoryChunkFlags;
    PropertyFlags:TVkMemoryPropertyFlags;
    HeapFlags:TVkMemoryHeapFlags;
begin

 result:=nil;

 if aMemoryBlockSize=0 then begin
  raise EpvVulkanMemoryAllocationException.Create('Can''t allocate zero-sized memory block');
 end;

 MemoryChunkFlags:=[];
 if vdmbfPersistentMapped in aMemoryBlockFlags then begin
  Include(MemoryChunkFlags,vdmcfPersistentMapped);
 end;

 if vdmbfOwnSingleMemoryChunk in aMemoryBlockFlags then begin

  // New allocated device memory blocks are always perfectly aligned already, so set Alignment here to 1 
  Alignment:=1;

  fLock.Acquire;
  try
   // Allocate a block inside a new chunk
   MemoryChunk:=TpvVulkanDeviceMemoryChunk.Create(self,
                                                MemoryChunkFlags,
                                                aMemoryBlockSize,
                                                false,
                                                aMemoryTypeBits,
                                                aMemoryRequiredPropertyFlags,
                                                aMemoryPreferredPropertyFlags,
                                                aMemoryAvoidPropertyFlags,
                                                aMemoryRequiredHeapFlags,
                                                aMemoryPreferredHeapFlags,
                                                aMemoryAvoidHeapFlags,
                                                @fMemoryChunkList);
   if MemoryChunk.AllocateMemory(Offset,aMemoryBlockSize,Alignment,aMemoryAllocationType) then begin
    result:=TpvVulkanDeviceMemoryBlock.Create(self,MemoryChunk,Offset,aMemoryBlockSize);
   end;
  finally
   fLock.Release;
  end;

 end else begin

  Alignment:=aMemoryBlockAlignment-1;
  Alignment:=Alignment or (Alignment shr 1);
  Alignment:=Alignment or (Alignment shr 2);
  Alignment:=Alignment or (Alignment shr 4);
  Alignment:=Alignment or (Alignment shr 8);
  Alignment:=Alignment or (Alignment shr 16);
  Alignment:=(Alignment or (Alignment shr 32))+1;

  fLock.Acquire;
  try

   // Try first to allocate a block inside already existent chunks
   for TryIteration:=0 to 3 do begin

    PropertyFlags:=aMemoryRequiredPropertyFlags;
    if TryIteration in [0,1] then begin
     if aMemoryPreferredPropertyFlags=0 then begin
      // For avoid unnecessary multiplicate fMemoryChunkList traversals
      continue;
     end else begin
      PropertyFlags:=PropertyFlags or aMemoryPreferredPropertyFlags;
     end;
    end;

    HeapFlags:=aMemoryRequiredHeapFlags;
    if TryIteration in [0,2] then begin
     if aMemoryPreferredHeapFlags=0 then begin
      // For avoid unnecessary multiplicate fMemoryChunkList traversals
      continue;
     end else begin
      HeapFlags:=HeapFlags or aMemoryPreferredHeapFlags;
     end;
    end;

    MemoryChunk:=fMemoryChunkList.First;
    while assigned(MemoryChunk) do begin
     if ((aMemoryTypeBits and MemoryChunk.fMemoryTypeBits)<>0) and
        ((MemoryChunk.fMemoryPropertyFlags and PropertyFlags)=PropertyFlags) and
        ((aMemoryAvoidPropertyFlags=0) or ((MemoryChunk.fMemoryPropertyFlags and aMemoryAvoidPropertyFlags)=0)) and
        ((MemoryChunk.fMemoryHeapFlags and HeapFlags)=HeapFlags) and
        ((aMemoryAvoidHeapFlags=0) or ((MemoryChunk.fMemoryHeapFlags and aMemoryAvoidHeapFlags)=0)) and
        ((MemoryChunk.fSize-MemoryChunk.fUsed)>=aMemoryBlockSize) and
        ((MemoryChunk.fMemoryChunkFlags*[vdmcfPersistentMapped])=(MemoryChunkFlags*[vdmcfPersistentMapped])) then begin
      if MemoryChunk.AllocateMemory(Offset,aMemoryBlockSize,Alignment,aMemoryAllocationType) then begin
       result:=TpvVulkanDeviceMemoryBlock.Create(self,MemoryChunk,Offset,aMemoryBlockSize);
       break;
      end;
     end;
     MemoryChunk:=MemoryChunk.fNextMemoryChunk;
    end;

    if assigned(result) then begin
     break;
    end;

   end;

   if not assigned(result) then begin
    // Otherwise allocate a block inside a new chunk

    MemoryChunk:=TpvVulkanDeviceMemoryChunk.Create(self,
                                                 MemoryChunkFlags,
                                                 VulkanDeviceSizeRoundUpToPowerOfTwo(Max(TpvInt64(VulkanMinimumMemoryChunkSize),TpvInt64(aMemoryBlockSize shl 1))),
                                                 true,
                                                 aMemoryTypeBits,
                                                 aMemoryRequiredPropertyFlags,
                                                 aMemoryPreferredPropertyFlags,
                                                 aMemoryAvoidPropertyFlags,
                                                 aMemoryRequiredHeapFlags,
                                                 aMemoryPreferredHeapFlags,
                                                 aMemoryAvoidHeapFlags,
                                                 @fMemoryChunkList);
    if MemoryChunk.AllocateMemory(Offset,aMemoryBlockSize,Alignment,aMemoryAllocationType) then begin
     result:=TpvVulkanDeviceMemoryBlock.Create(self,MemoryChunk,Offset,aMemoryBlockSize);
    end;
   end;

  finally
   fLock.Release;
  end;

 end;

 if not assigned(result) then begin
  raise EpvVulkanMemoryAllocationException.Create('Couldn''t allocate memory block');
 end;

end;

function TpvVulkanDeviceMemoryManager.FreeMemoryBlock(const aMemoryBlock:TpvVulkanDeviceMemoryBlock):boolean;
var MemoryChunk:TpvVulkanDeviceMemoryChunk;
begin
 result:=assigned(aMemoryBlock);
 if result then begin
  fLock.Acquire;
  try
   MemoryChunk:=aMemoryBlock.fMemoryChunk;
   result:=MemoryChunk.FreeMemory(aMemoryBlock.fOffset);
   if result then begin
    aMemoryBlock.Free;
    if assigned(MemoryChunk.fOffsetRedBlackTree.fRoot) and
       (MemoryChunk.fOffsetRedBlackTree.fRoot.fValue.fOffset=0) and
       (MemoryChunk.fOffsetRedBlackTree.fRoot.fValue.fSize=MemoryChunk.fSize) and
       not (assigned(MemoryChunk.fOffsetRedBlackTree.fRoot.fLeft) or assigned(MemoryChunk.fOffsetRedBlackTree.fRoot.fRight)) then begin
     MemoryChunk.Free;
    end;
   end;
  finally
   fLock.Release;
  end;
 end;
end;

constructor TpvVulkanBuffer.Create(const aDevice:TpvVulkanDevice;
                                   const aSize:TVkDeviceSize;
                                   const aUsage:TVkBufferUsageFlags;
                                   const aSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                                   const aQueueFamilyIndices:TVkUInt32List=nil;
                                   const aMemoryRequiredPropertyFlags:TVkMemoryPropertyFlags=TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
                                   const aMemoryPreferredPropertyFlags:TVkMemoryPropertyFlags=TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT);
                                   const aMemoryAvoidPropertyFlags:TVkMemoryPropertyFlags=0;
                                   const aMemoryRequiredHeapFlags:TVkMemoryHeapFlags=0;
                                   const aMemoryPreferredHeapFlags:TVkMemoryHeapFlags=0;
                                   const aMemoryAvoidHeapFlags:TVkMemoryHeapFlags=0;
                                   const aBufferFlags:TpvVulkanBufferFlags=[]);
var Index:TpvInt32;
    BufferCreateInfo:TVkBufferCreateInfo;
    MemoryBlockFlags:TpvVulkanDeviceMemoryBlockFlags;
begin
 inherited Create;

 fDevice:=aDevice;

 fSize:=aSize;

 fBufferFlags:=aBufferFlags;

 fBufferHandle:=VK_NULL_HANDLE;

 fMemoryBlock:=nil;

 fQueueFamilyIndices:=nil;
 if assigned(aQueueFamilyIndices) then begin
  fCountQueueFamilyIndices:=aQueueFamilyIndices.Count;
  SetLength(fQueueFamilyIndices,fCountQueueFamilyIndices);
  for Index:=0 to fCountQueueFamilyIndices-1 do begin
   fQueueFamilyIndices[Index]:=aQueueFamilyIndices.Items[Index];
  end;
 end else begin
  fCountQueueFamilyIndices:=0;
 end;

 FillChar(BufferCreateInfo,SizeOf(TVkBufferCreateInfo),#0);
 BufferCreateInfo.sType:=VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
 BufferCreateInfo.size:=fSize;
 BufferCreateInfo.usage:=aUsage;
 BufferCreateInfo.sharingMode:=aSharingMode;
 if fCountQueueFamilyIndices>0 then begin
  BufferCreateInfo.pQueueFamilyIndices:=@fQueueFamilyIndices[0];
  BufferCreateInfo.queueFamilyIndexCount:=fCountQueueFamilyIndices;
 end;

 try

  HandleResultCode(fDevice.Commands.CreateBuffer(fDevice.fDeviceHandle,@BufferCreateInfo,fDevice.fAllocationCallbacks,@fBufferHandle));

  fDevice.Commands.GetBufferMemoryRequirements(fDevice.fDeviceHandle,fBufferHandle,@fMemoryRequirements);

  MemoryBlockFlags:=[];
  if vbfOwnSingleMemoryChunk in fBufferFlags then begin
   Include(MemoryBlockFlags,vdmbfOwnSingleMemoryChunk);
  end;
  if vbfPersistentMapped in fBufferFlags then begin
   Include(MemoryBlockFlags,vdmbfPersistentMapped);
  end;

  fMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock(MemoryBlockFlags,
                                                           fMemoryRequirements.Size,
                                                           fMemoryRequirements.Alignment,
                                                           fMemoryRequirements.memoryTypeBits,
                                                           aMemoryRequiredPropertyFlags,
                                                           aMemoryPreferredPropertyFlags,
                                                           aMemoryAvoidPropertyFlags,
                                                           aMemoryRequiredHeapFlags,
                                                           aMemoryPreferredHeapFlags,
                                                           aMemoryAvoidHeapFlags,
                                                           vdmatBuffer);

  Bind;

  fMemoryPropertyFlags:=fMemoryBlock.fMemoryChunk.fMemoryPropertyFlags;

  fDescriptorBufferInfo.buffer:=fBufferHandle;
  fDescriptorBufferInfo.offset:=0;
  fDescriptorBufferInfo.range:=fSize;

 except

  if fBufferHandle<>VK_NULL_HANDLE then begin
   fDevice.Commands.DestroyBuffer(fDevice.fDeviceHandle,fBufferHandle,fDevice.fAllocationCallbacks);
   fBufferHandle:=VK_NULL_HANDLE;
  end;

  if assigned(fMemoryBlock) then begin
   fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
   fMemoryBlock:=nil;
  end;

  SetLength(fQueueFamilyIndices,0);

  raise;

 end;

end;

destructor TpvVulkanBuffer.Destroy;
begin
 if fBufferHandle<>VK_NULL_HANDLE then begin
  fDevice.Commands.DestroyBuffer(fDevice.fDeviceHandle,fBufferHandle,fDevice.fAllocationCallbacks);
  fBufferHandle:=VK_NULL_HANDLE;
 end;
 if assigned(fMemoryBlock) then begin
  fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
  fMemoryBlock:=nil;
 end;
 SetLength(fQueueFamilyIndices,0);
 inherited Destroy;
end;

procedure TpvVulkanBuffer.Bind;
begin
 HandleResultCode(fDevice.Commands.BindBufferMemory(fDevice.fDeviceHandle,fBufferHandle,fMemoryBlock.fMemoryChunk.fMemoryHandle,fMemoryBlock.fOffset));
end;

procedure TpvVulkanBuffer.UploadData(const aTransferQueue:TpvVulkanQueue;
                                     const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                     const aTransferFence:TpvVulkanFence;
                                     const aData;
                                     const aDataOffset:TVkDeviceSize;
                                     const aDataSize:TVkDeviceSize;
                                     const aUseTemporaryStagingBufferMode:TpvVulkanBufferUseTemporaryStagingBufferMode=vbutsbmAutomatic);
var StagingBuffer:TpvVulkanBuffer;
    p:TpvPointer;
    VkBufferCopy:TVkBufferCopy;
begin

 if (aUseTemporaryStagingBufferMode=vbutsbmYes) or
    ((aUseTemporaryStagingBufferMode=vbutsbmAutomatic) and
     ((fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))=0)) then begin

  StagingBuffer:=TpvVulkanBuffer.Create(fDevice,
                                      aDataSize,
                                      TVkBufferUsageFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
                                      VK_SHARING_MODE_EXCLUSIVE,
                                      nil,
                                      TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT),
                                      0,
                                      0,
                                      0,
                                      0,
                                      0,
                                      [vbfOwnSingleMemoryChunk]);
  try

   p:=StagingBuffer.Memory.MapMemory;
   try
    if assigned(p) then begin
     Move(aData,p^,aDataSize);
    end else begin
     raise EpvVulkanException.Create('Vulkan buffer memory block map failed');
    end;
   finally
    StagingBuffer.Memory.UnmapMemory;
   end;

   VkBufferCopy.srcOffset:=0;
   VkBufferCopy.dstOffset:=aDataOffset;
   VkBufferCopy.size:=aDataSize;

   aTransferCommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
   aTransferCommandBuffer.BeginRecording;
   aTransferCommandBuffer.CmdCopyBuffer(StagingBuffer.Handle,Handle,1,@VkBufferCopy);
   aTransferCommandBuffer.EndRecording;
   aTransferCommandBuffer.Execute(fDevice.TransferQueue,0,nil,nil,aTransferFence,true);

  finally
   StagingBuffer.Free;
  end;

 end else begin

  if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
   p:=Memory.MapMemory(aDataOffset,aDataSize);
   try
    if assigned(p) then begin
     Move(aData,p^,aDataSize);
     if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))=0 then begin
      Memory.FlushMappedMemoryRange(p,aDataSize);
     end;
    end else begin
     raise EpvVulkanException.Create('Vulkan buffer memory block map failed');
    end;
   finally
    Memory.UnmapMemory;
   end;
  end else begin
   raise EpvVulkanException.Create('Vulkan buffer memory block map failed');
  end;

 end;

end;

procedure TpvVulkanBuffer.UpdateData(const aData;
                                     const aDataOffset:TVkDeviceSize;
                                     const aDataSize:TVkDeviceSize);
var p:TpvPointer;
begin
 if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT))<>0 then begin
  p:=Memory.MapMemory(aDataOffset,aDataSize);
  try
   if assigned(p) then begin
    Move(aData,p^,aDataSize);
    if (fMemoryPropertyFlags and TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT))=0 then begin
     Memory.FlushMappedMemoryRange(p,aDataSize);
    end;
   end else begin
    raise EpvVulkanException.Create('Vulkan buffer memory block map failed');
   end;
  finally
   Memory.UnmapMemory;
  end;
 end else begin
  raise EpvVulkanException.Create('Vulkan buffer memory block map failed');
 end;
end;

constructor TpvVulkanBufferView.Create(const aDevice:TpvVulkanDevice;
                                       const aBuffer:TpvVulkanBuffer;
                                       const aFormat:TVkFormat;
                                       const aOffset:TVkDeviceSize=0;
                                       const aRange:TVkDeviceSize=TVkDeviceSize(VK_WHOLE_SIZE));
var BufferViewCreateInfo:TVkBufferViewCreateInfo;
begin

 inherited Create;

 fDevice:=aDevice;

 fBuffer:=aBuffer;

 fBufferViewHandle:=VK_NULL_HANDLE;

 FillChar(BufferViewCreateInfo,SizeOf(TVkBufferViewCreateInfo),#0);
 BufferViewCreateInfo.sType:=VK_STRUCTURE_TYPE_BUFFER_VIEW_CREATE_INFO;
 BufferViewCreateInfo.pNext:=nil;
 BufferViewCreateInfo.flags:=0;
 BufferViewCreateInfo.buffer:=fBuffer.fBufferHandle;
 BufferViewCreateInfo.format:=aFormat;
 BufferViewCreateInfo.offset:=aOffset;
 BufferViewCreateInfo.range:=aRange;

 HandleResultCode(fDevice.fDeviceVulkan.CreateBufferView(fDevice.fDeviceHandle,@BufferViewCreateInfo,fDevice.fAllocationCallbacks,@fBufferViewHandle));

end;

constructor TpvVulkanBufferView.Create(const aDevice:TpvVulkanDevice;
                                       const aBufferView:TVkBufferView;
                                       const aBuffer:TpvVulkanBuffer=nil);
begin

 inherited Create;

 fDevice:=aDevice;

 fBufferViewHandle:=aBufferView;

 fBuffer:=aBuffer;

end;

destructor TpvVulkanBufferView.Destroy;
begin
 fBuffer:=nil;
 if fBufferViewHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyBufferView(fDevice.fDeviceHandle,fBufferViewHandle,fDevice.fAllocationCallbacks);
  fBufferViewHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanEvent.Create(const aDevice:TpvVulkanDevice;
                                  const aFlags:TVkEventCreateFlags=TVkEventCreateFlags(0));
var EventCreateInfo:TVkEventCreateInfo;
begin
 inherited Create;

 fDevice:=aDevice;

 fEventHandle:=VK_NULL_HANDLE;

 FillChar(EventCreateInfo,SizeOf(TVkEventCreateInfo),#0);
 EventCreateInfo.sType:=VK_STRUCTURE_TYPE_EVENT_CREATE_INFO;
 EventCreateInfo.pNext:=nil;
 EventCreateInfo.flags:=aFlags;

 HandleResultCode(fDevice.fDeviceVulkan.CreateEvent(fDevice.fDeviceHandle,@EventCreateInfo,fDevice.fAllocationCallbacks,@fEventHandle));

end;

destructor TpvVulkanEvent.Destroy;
begin
 if fEventHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyEvent(fDevice.fDeviceHandle,fEventHandle,fDevice.fAllocationCallbacks);
  fEventHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

function TpvVulkanEvent.GetStatus:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.GetEventStatus(fDevice.fDeviceHandle,fEventHandle);
end;

function TpvVulkanEvent.SetEvent:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.SetEvent(fDevice.fDeviceHandle,fEventHandle);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

function TpvVulkanEvent.Reset:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.ResetEvent(fDevice.fDeviceHandle,fEventHandle);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

constructor TpvVulkanFence.Create(const aDevice:TpvVulkanDevice;
                                  const aFlags:TVkFenceCreateFlags=TVkFenceCreateFlags(0));
var FenceCreateInfo:TVkFenceCreateInfo;
begin
 inherited Create;

 fDevice:=aDevice;

 fFenceHandle:=VK_NULL_HANDLE;

 FillChar(FenceCreateInfo,SizeOf(TVkFenceCreateInfo),#0);
 FenceCreateInfo.sType:=VK_STRUCTURE_TYPE_FENCE_CREATE_INFO;
 FenceCreateInfo.pNext:=nil;
 FenceCreateInfo.flags:=aFlags;

 HandleResultCode(fDevice.fDeviceVulkan.CreateFence(fDevice.fDeviceHandle,@FenceCreateInfo,fDevice.fAllocationCallbacks,@fFenceHandle));

end;

destructor TpvVulkanFence.Destroy;
begin
 if fFenceHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyFence(fDevice.fDeviceHandle,fFenceHandle,fDevice.fAllocationCallbacks);
  fFenceHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

function TpvVulkanFence.GetStatus:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.GetFenceStatus(fDevice.fDeviceHandle,fFenceHandle);
end;

function TpvVulkanFence.Reset:TVkResult;
begin
 result:=fDevice.fDeviceVulkan.ResetFences(fDevice.fDeviceHandle,1,@fFenceHandle);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

class function TpvVulkanFence.Reset(const aFences:array of TpvVulkanFence):TVkResult;
var Index:TpvInt32;
    Handles:array of TVkFence;
begin
 Handles:=nil;
 result:=VK_SUCCESS;
 if length(aFences)>0 then begin
  try
   SetLength(Handles,length(aFences));
   for Index:=0 to length(aFences)-1 do begin
    Handles[Index]:=aFences[Index].fFenceHandle;
   end;
   result:=aFences[0].fDevice.fDeviceVulkan.ResetFences(aFences[0].fDevice.fDeviceHandle,length(aFences),@Handles[0]);
  finally
   SetLength(Handles,0);
  end;
  if result<VK_SUCCESS then begin
   HandleResultCode(result);
  end;
 end;
end;

function TpvVulkanFence.WaitFor(const aTimeOut:TpvUInt64=TpvUInt64(TpvInt64(-1))):TVkResult;
begin
 result:=fDevice.fDeviceVulkan.WaitForFences(fDevice.fDeviceHandle,1,@fFenceHandle,VK_TRUE,aTimeOut);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

class function TpvVulkanFence.WaitFor(const aFences:array of TpvVulkanFence;const aWaitAll:boolean=true;const aTimeOut:TpvUInt64=TpvUInt64(TpvInt64(-1))):TVkResult;
var Index:TpvInt32;
    Handles:array of TVkFence;
begin
 Handles:=nil;
 result:=VK_SUCCESS;
 if length(aFences)>0 then begin
  try
   SetLength(Handles,length(aFences));
   for Index:=0 to length(aFences)-1 do begin
    Handles[Index]:=aFences[Index].fFenceHandle;
   end;
   if aWaitAll then begin
    result:=aFences[0].fDevice.fDeviceVulkan.WaitForFences(aFences[0].fDevice.fDeviceHandle,length(aFences),@Handles[0],VK_TRUE,aTimeOut);
   end else begin
    result:=aFences[0].fDevice.fDeviceVulkan.WaitForFences(aFences[0].fDevice.fDeviceHandle,length(aFences),@Handles[0],VK_FALSE,aTimeOut);
   end;
  finally
   SetLength(Handles,0);
  end;
  if result<VK_SUCCESS then begin
   HandleResultCode(result);
  end;
 end;
end;

constructor TpvVulkanSemaphore.Create(const aDevice:TpvVulkanDevice;
                                      const aFlags:TVkSemaphoreCreateFlags=TVkSemaphoreCreateFlags(0));
var SemaphoreCreateInfo:TVkSemaphoreCreateInfo;
begin
 inherited Create;

 fDevice:=aDevice;

 fSemaphoreHandle:=VK_NULL_HANDLE;

 FillChar(SemaphoreCreateInfo,SizeOf(TVkSemaphoreCreateInfo),#0);
 SemaphoreCreateInfo.sType:=VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;
 SemaphoreCreateInfo.pNext:=nil;
 SemaphoreCreateInfo.flags:=aFlags;

 HandleResultCode(fDevice.fDeviceVulkan.CreateSemaphore(fDevice.fDeviceHandle,@SemaphoreCreateInfo,fDevice.fAllocationCallbacks,@fSemaphoreHandle));

end;

destructor TpvVulkanSemaphore.Destroy;
begin
 if fSemaphoreHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroySemaphore(fDevice.fDeviceHandle,fSemaphoreHandle,fDevice.fAllocationCallbacks);
  fSemaphoreHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanQueue.Create(const aDevice:TpvVulkanDevice;
                                  const aQueue:TVkQueue;
                                  const aQueueFamilyIndex:TpvUInt32);
begin
 inherited Create;

 fDevice:=aDevice;

 fQueueHandle:=aQueue;

 fQueueFamilyIndex:=aQueueFamilyIndex;

 fHasSupportForSparseBindings:=fDevice.fPhysicalDevice.HasQueueSupportForSparseBindings(aQueueFamilyIndex);

end;

destructor TpvVulkanQueue.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanQueue.Submit(const aSubmitCount:TpvUInt32;const aSubmits:PVkSubmitInfo;const aFence:TpvVulkanFence=nil);
begin
 if assigned(aFence) then begin
  HandleResultCode(fDevice.fDeviceVulkan.QueueSubmit(fQueueHandle,aSubmitCount,aSubmits,aFence.fFenceHandle));
 end else begin
  HandleResultCode(fDevice.fDeviceVulkan.QueueSubmit(fQueueHandle,aSubmitCount,aSubmits,VK_NULL_HANDLE));
 end;
end;

procedure TpvVulkanQueue.BindSparse(const aBindInfoCount:TpvUInt32;const aBindInfo:PVkBindSparseInfo;const aFence:TpvVulkanFence=nil);
begin
 if assigned(aFence) then begin
  HandleResultCode(fDevice.fDeviceVulkan.QueueBindSparse(fQueueHandle,aBindInfoCount,aBindInfo,aFence.fFenceHandle));
 end else begin
  HandleResultCode(fDevice.fDeviceVulkan.QueueBindSparse(fQueueHandle,aBindInfoCount,aBindInfo,VK_NULL_HANDLE));
 end;
end;

procedure TpvVulkanQueue.WaitIdle;
begin
 HandleResultCode(fDevice.fDeviceVulkan.QueueWaitIdle(fQueueHandle));
end;

constructor TpvVulkanCommandPool.Create(const aDevice:TpvVulkanDevice;
                                        const aQueueFamilyIndex:TpvUInt32;
                                        const aFlags:TVkCommandPoolCreateFlags=TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
var CommandPoolCreateInfo:TVkCommandPoolCreateInfo;
begin
 inherited Create;

 fDevice:=aDevice;

 fQueueFamilyIndex:=aQueueFamilyIndex;

 fFlags:=aFlags;

 fCommandPoolHandle:=VK_NULL_HANDLE;

 FillChar(CommandPoolCreateInfo,SizeOf(TVkCommandPoolCreateInfo),#0);
 CommandPoolCreateInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
 CommandPoolCreateInfo.queueFamilyIndex:=fQueueFamilyIndex;
 CommandPoolCreateInfo.flags:=fFlags;
 HandleResultCode(fDevice.fDeviceVulkan.CreateCommandPool(fDevice.fDeviceHandle,@CommandPoolCreateInfo,fDevice.fAllocationCallbacks,@fCommandPoolHandle));

end;

destructor TpvVulkanCommandPool.Destroy;
begin
 if fCommandPoolHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyCommandPool(fDevice.fDeviceHandle,fCommandPoolHandle,fDevice.fAllocationCallbacks);
  fCommandPoolHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanCommandBuffer.Create(const aCommandPool:TpvVulkanCommandPool;
                                          const aLevel:TVkCommandBufferLevel;
                                          const aCommandBufferHandle:TVkCommandBuffer);
begin

 fDevice:=aCommandPool.fDevice;

 fCommandPool:=aCommandPool;

 fLevel:=aLevel;

 fCommandBufferHandle:=aCommandBufferHandle;

{if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin
  fFence:=TpvVulkanFence.Create(fDevice);
 end else begin
  fFence:=nil;
 end;{}

end;

constructor TpvVulkanCommandBuffer.Create(const aCommandPool:TpvVulkanCommandPool;
                                          const aLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY);
var CommandBufferAllocateInfo:TVkCommandBufferAllocateInfo;
begin
 inherited Create;

 fDevice:=aCommandPool.fDevice;

 fCommandPool:=aCommandPool;

 fLevel:=aLevel;

 fCommandBufferHandle:=VK_NULL_HANDLE;

{if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin
  fFence:=TpvVulkanFence.Create(fDevice);
 end else begin
  fFence:=nil;
 end;{}

 FillChar(CommandBufferAllocateInfo,SizeOf(TVkCommandBufferAllocateInfo),#0);
 CommandBufferAllocateInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
 CommandBufferAllocateInfo.commandPool:=fCommandPool.fCommandPoolHandle;
 CommandBufferAllocateInfo.level:=aLevel;
 CommandBufferAllocateInfo.commandBufferCount:=1;

 HandleResultCode(fDevice.fDeviceVulkan.AllocateCommandBuffers(fDevice.fDeviceHandle,@CommandBufferAllocateInfo,@fCommandBufferHandle));

end;

destructor TpvVulkanCommandBuffer.Destroy;
begin
 if fCommandBufferHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.FreeCommandBuffers(fDevice.fDeviceHandle,fCommandPool.fCommandPoolHandle,1,@fCommandBufferHandle);
  fCommandBufferHandle:=VK_NULL_HANDLE;
 end;
//FreeAndNil(fFence);
 inherited Destroy;
end;

class function TpvVulkanCommandBuffer.Allocate(const aCommandPool:TpvVulkanCommandPool;
                                               const aLevel:TVkCommandBufferLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY;
                                               const aCommandBufferCount:TpvUInt32=1):TpvVulkanObjectList;
var Index:TpvInt32;
    CommandBufferHandles:array of TVkCommandBuffer;
    CommandBufferAllocateInfo:TVkCommandBufferAllocateInfo;
begin
 result:=nil;
 CommandBufferHandles:=nil;
 try
  SetLength(CommandBufferHandles,aCommandBufferCount);

  FillChar(CommandBufferAllocateInfo,SizeOf(TVkCommandBufferAllocateInfo),#0);
  CommandBufferAllocateInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
  CommandBufferAllocateInfo.commandPool:=aCommandPool.fCommandPoolHandle;
  CommandBufferAllocateInfo.level:=aLevel;
  CommandBufferAllocateInfo.commandBufferCount:=aCommandBufferCount;

  HandleResultCode(aCommandPool.fDevice.fDeviceVulkan.AllocateCommandBuffers(aCommandPool.fDevice.fDeviceHandle,@CommandBufferAllocateInfo,@CommandBufferHandles[0]));

  result:=TpvVulkanObjectList.Create;
  for Index:=0 to aCommandBufferCount-1 do begin
   result.Add(TpvVulkanCommandBuffer.Create(aCommandPool,aLevel,CommandBufferHandles[Index]));
  end;

 finally
  SetLength(CommandBufferHandles,0);
 end;
end;

procedure TpvVulkanCommandBuffer.BeginRecording(const aFlags:TVkCommandBufferUsageFlags=0;const aInheritanceInfo:PVkCommandBufferInheritanceInfo=nil);
var CommandBufferBeginInfo:TVkCommandBufferBeginInfo;
begin
 FillChar(CommandBufferBeginInfo,SizeOf(TVkCommandBufferBeginInfo),#0);
 CommandBufferBeginInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
 CommandBufferBeginInfo.pNext:=nil;
 CommandBufferBeginInfo.flags:=aFlags;
 CommandBufferBeginInfo.pInheritanceInfo:=aInheritanceInfo;
 HandleResultCode(fDevice.fDeviceVulkan.BeginCommandBuffer(fCommandBufferHandle,@CommandBufferBeginInfo));
end;

procedure TpvVulkanCommandBuffer.BeginRecordingPrimary;
var CommandBufferBeginInfo:TVkCommandBufferBeginInfo;
begin
 if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin
  FillChar(CommandBufferBeginInfo,SizeOf(TVkCommandBufferBeginInfo),#0);
  CommandBufferBeginInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  CommandBufferBeginInfo.pNext:=nil;
  CommandBufferBeginInfo.flags:=0;
  CommandBufferBeginInfo.pInheritanceInfo:=nil;
  HandleResultCode(fDevice.fDeviceVulkan.BeginCommandBuffer(fCommandBufferHandle,@CommandBufferBeginInfo));
 end else begin
  raise EpvVulkanException.Create('BeginRecordingPrimary called from a non-primary command buffer!');
 end;
end;

procedure TpvVulkanCommandBuffer.BeginRecordingSecondary(const aRenderPass:TVkRenderPass;const aSubPass:TpvUInt32;const aFrameBuffer:TVkFramebuffer;const aOcclusionQueryEnable:boolean;const aQueryFlags:TVkQueryControlFlags;const aPipelineStatistics:TVkQueryPipelineStatisticFlags;const aFlags:TVkCommandBufferUsageFlags=TVkCommandBufferUsageFlags(VK_COMMAND_BUFFER_USAGE_RENDER_PASS_CONTINUE_BIT));
var CommandBufferBeginInfo:TVkCommandBufferBeginInfo;
    InheritanceInfo:TVkCommandBufferInheritanceInfo;
begin
 if fLevel=VK_COMMAND_BUFFER_LEVEL_SECONDARY then begin
  FillChar(InheritanceInfo,SizeOf(TVkCommandBufferInheritanceInfo),#0);
  InheritanceInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_INHERITANCE_INFO;
  InheritanceInfo.pNext:=nil;
  InheritanceInfo.renderPass:=aRenderPass;
  InheritanceInfo.subpass:=aSubPass;
  InheritanceInfo.framebuffer:=aFrameBuffer;
  if aOcclusionQueryEnable then begin
   InheritanceInfo.occlusionQueryEnable:=VK_TRUE;
  end else begin
   InheritanceInfo.occlusionQueryEnable:=VK_FALSE;
  end;
  InheritanceInfo.queryFlags:=aQueryFlags;
  InheritanceInfo.pipelineStatistics:=aPipelineStatistics;
  FillChar(CommandBufferBeginInfo,SizeOf(TVkCommandBufferBeginInfo),#0);
  CommandBufferBeginInfo.sType:=VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
  CommandBufferBeginInfo.pNext:=nil;
  CommandBufferBeginInfo.flags:=aFlags;
  CommandBufferBeginInfo.pInheritanceInfo:=@InheritanceInfo;
  HandleResultCode(fDevice.fDeviceVulkan.BeginCommandBuffer(fCommandBufferHandle,@CommandBufferBeginInfo));
 end else begin
  raise EpvVulkanException.Create('BeginRecordingSecondary called from a non-secondary command buffer!');
 end;
end;

procedure TpvVulkanCommandBuffer.EndRecording;
begin
 HandleResultCode(fDevice.fDeviceVulkan.EndCommandBuffer(fCommandBufferHandle));
end;

procedure TpvVulkanCommandBuffer.Reset(const aFlags:TVkCommandBufferResetFlags=TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
begin
 HandleResultCode(fDevice.fDeviceVulkan.ResetCommandBuffer(fCommandBufferHandle,aFlags));
end;

procedure TpvVulkanCommandBuffer.CmdBindPipeline(pipelineBindPoint:TVkPipelineBindPoint;pipeline:TVkPipeline);
begin
 fDevice.fDeviceVulkan.CmdBindPipeline(fCommandBufferHandle,pipelineBindPoint,pipeline);
end;

procedure TpvVulkanCommandBuffer.CmdSetViewport(firstViewport:TpvUInt32;viewportCount:TpvUInt32;const aViewports:PVkViewport);
begin
 fDevice.fDeviceVulkan.CmdSetViewport(fCommandBufferHandle,firstViewport,viewportCount,aViewports);
end;

procedure TpvVulkanCommandBuffer.CmdSetScissor(firstScissor:TpvUInt32;scissorCount:TpvUInt32;const aScissors:PVkRect2D);
begin
 fDevice.fDeviceVulkan.CmdSetScissor(fCommandBufferHandle,firstScissor,scissorCount,aScissors);
end;

procedure TpvVulkanCommandBuffer.CmdSetLineWidth(lineWidth:TpvFloat);
begin
 fDevice.fDeviceVulkan.CmdSetLineWidth(fCommandBufferHandle,lineWidth);
end;

procedure TpvVulkanCommandBuffer.CmdSetDepthBias(depthBiasConstantFactor:TpvFloat;depthBiasClamp:TpvFloat;depthBiasSlopeFactor:TpvFloat);
begin
 fDevice.fDeviceVulkan.CmdSetDepthBias(fCommandBufferHandle,depthBiasConstantFactor,depthBiasClamp,depthBiasSlopeFactor);
end;

procedure TpvVulkanCommandBuffer.CmdSetBlendConstants(const blendConstants:TpvFloat);
begin
 fDevice.fDeviceVulkan.CmdSetBlendConstants(fCommandBufferHandle,blendConstants);
end;

procedure TpvVulkanCommandBuffer.CmdSetDepthBounds(minDepthBounds:TpvFloat;maxDepthBounds:TpvFloat);
begin
 fDevice.fDeviceVulkan.CmdSetDepthBounds(fCommandBufferHandle,minDepthBounds,maxDepthBounds);
end;

procedure TpvVulkanCommandBuffer.CmdSetStencilCompareMask(faceMask:TVkStencilFaceFlags;compareMask:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdSetStencilCompareMask(fCommandBufferHandle,faceMask,compareMask);
end;

procedure TpvVulkanCommandBuffer.CmdSetStencilWriteMask(faceMask:TVkStencilFaceFlags;writeMask:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdSetStencilWriteMask(fCommandBufferHandle,faceMask,writeMask);
end;

procedure TpvVulkanCommandBuffer.CmdSetStencilReference(faceMask:TVkStencilFaceFlags;reference:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdSetStencilReference(fCommandBufferHandle,faceMask,reference);
end;

procedure TpvVulkanCommandBuffer.CmdBindDescriptorSets(pipelineBindPoint:TVkPipelineBindPoint;layout:TVkPipelineLayout;firstSet:TpvUInt32;descriptorSetCount:TpvUInt32;const aDescriptorSets:PVkDescriptorSet;dynamicOffsetCount:TpvUInt32;const aDynamicOffsets:PpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdBindDescriptorSets(fCommandBufferHandle,pipelineBindPoint,layout,firstSet,descriptorSetCount,aDescriptorSets,dynamicOffsetCount,TVkPointer(aDynamicOffsets));
end;

procedure TpvVulkanCommandBuffer.CmdBindIndexBuffer(buffer:TVkBuffer;offset:TVkDeviceSize;indexType:TVkIndexType);
begin
 fDevice.fDeviceVulkan.CmdBindIndexBuffer(fCommandBufferHandle,buffer,offset,indexType);
end;

procedure TpvVulkanCommandBuffer.CmdBindVertexBuffers(firstBinding:TpvUInt32;bindingCount:TpvUInt32;const aBuffers:PVkBuffer;const aOffsets:PVkDeviceSize);
begin
 fDevice.fDeviceVulkan.CmdBindVertexBuffers(fCommandBufferHandle,firstBinding,bindingCount,aBuffers,aOffsets);
end;

procedure TpvVulkanCommandBuffer.CmdDraw(vertexCount:TpvUInt32;instanceCount:TpvUInt32;firstVertex:TpvUInt32;firstInstance:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdDraw(fCommandBufferHandle,vertexCount,instanceCount,firstVertex,firstInstance);
end;

procedure TpvVulkanCommandBuffer.CmdDrawIndexed(indexCount:TpvUInt32;instanceCount:TpvUInt32;firstIndex:TpvUInt32;vertexOffset:TpvInt32;firstInstance:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdDrawIndexed(fCommandBufferHandle,indexCount,instanceCount,firstIndex,vertexOffset,firstInstance);
end;

procedure TpvVulkanCommandBuffer.CmdDrawIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TpvUInt32;stride:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdDrawIndirect(fCommandBufferHandle,buffer,offset,drawCount,stride);
end;

procedure TpvVulkanCommandBuffer.CmdDrawIndexedIndirect(buffer:TVkBuffer;offset:TVkDeviceSize;drawCount:TpvUInt32;stride:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdDrawIndexedIndirect(fCommandBufferHandle,buffer,offset,drawCount,stride);
end;

procedure TpvVulkanCommandBuffer.CmdDispatch(x:TpvUInt32;y:TpvUInt32;z:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdDispatch(fCommandBufferHandle,x,y,z);
end;

procedure TpvVulkanCommandBuffer.CmdDispatchIndirect(buffer:TVkBuffer;offset:TVkDeviceSize);
begin
 fDevice.fDeviceVulkan.CmdDispatchIndirect(fCommandBufferHandle,buffer,offset);
end;

procedure TpvVulkanCommandBuffer.CmdCopyBuffer(srcBuffer:TVkBuffer;dstBuffer:TVkBuffer;regionCount:TpvUInt32;const aRegions:PVkBufferCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyBuffer(fCommandBufferHandle,srcBuffer,dstBuffer,regionCount,aRegions);
end;

procedure TpvVulkanCommandBuffer.CmdCopyImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkImageCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyImage(fCommandBufferHandle,srcImage,srcImageLayout,dstImage,dstImageLayout,regionCount,aRegions);
end;

procedure TpvVulkanCommandBuffer.CmdBlitImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkImageBlit;filter:TVkFilter);
begin
 fDevice.fDeviceVulkan.CmdBlitImage(fCommandBufferHandle,srcImage,srcImageLayout,dstImage,dstImageLayout,regionCount,aRegions,filter);
end;

procedure TpvVulkanCommandBuffer.CmdCopyBufferToImage(srcBuffer:TVkBuffer;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkBufferImageCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyBufferToImage(fCommandBufferHandle,srcBuffer,dstImage,dstImageLayout,regionCount,aRegions);
end;

procedure TpvVulkanCommandBuffer.CmdCopyImageToBuffer(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstBuffer:TVkBuffer;regionCount:TpvUInt32;const aRegions:PVkBufferImageCopy);
begin
 fDevice.fDeviceVulkan.CmdCopyImageToBuffer(fCommandBufferHandle,srcImage,srcImageLayout,dstBuffer,regionCount,aRegions);
end;                                                                                             

procedure TpvVulkanCommandBuffer.CmdUpdateBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;dataSize:TVkDeviceSize;const aData:PVkVoid);
begin
 fDevice.fDeviceVulkan.CmdUpdateBuffer(fCommandBufferHandle,dstBuffer,dstOffset,dataSize,aData);
end;

procedure TpvVulkanCommandBuffer.CmdFillBuffer(dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;size:TVkDeviceSize;data:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdFillBuffer(fCommandBufferHandle,dstBuffer,dstOffset,size,data);
end;

procedure TpvVulkanCommandBuffer.CmdClearColorImage(image:TVkImage;imageLayout:TVkImageLayout;const aColor:PVkClearColorValue;rangeCount:TpvUInt32;const aRanges:PVkImageSubresourceRange);
begin
 fDevice.fDeviceVulkan.CmdClearColorImage(fCommandBufferHandle,image,imageLayout,aColor,rangeCount,aRanges);
end;

procedure TpvVulkanCommandBuffer.CmdClearDepthStencilImage(image:TVkImage;imageLayout:TVkImageLayout;const aDepthStencil:PVkClearDepthStencilValue;rangeCount:TpvUInt32;const aRanges:PVkImageSubresourceRange);
begin
 fDevice.fDeviceVulkan.CmdClearDepthStencilImage(fCommandBufferHandle,image,imageLayout,aDepthStencil,rangeCount,aRanges);
end;

procedure TpvVulkanCommandBuffer.CmdClearAttachments(attachmentCount:TpvUInt32;const aAttachments:PVkClearAttachment;rectCount:TpvUInt32;const aRects:PVkClearRect);
begin
 fDevice.fDeviceVulkan.CmdClearAttachments(fCommandBufferHandle,attachmentCount,aAttachments,rectCount,aRects);
end;

procedure TpvVulkanCommandBuffer.CmdResolveImage(srcImage:TVkImage;srcImageLayout:TVkImageLayout;dstImage:TVkImage;dstImageLayout:TVkImageLayout;regionCount:TpvUInt32;const aRegions:PVkImageResolve);
begin
 fDevice.fDeviceVulkan.CmdResolveImage(fCommandBufferHandle,srcImage,srcImageLayout,dstImage,dstImageLayout,regionCount,aRegions);
end;

procedure TpvVulkanCommandBuffer.CmdSetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
begin
 fDevice.fDeviceVulkan.CmdSetEvent(fCommandBufferHandle,event,stageMask);
end;

procedure TpvVulkanCommandBuffer.CmdResetEvent(event:TVkEvent;stageMask:TVkPipelineStageFlags);
begin
 fDevice.fDeviceVulkan.CmdResetEvent(fCommandBufferHandle,event,stageMask);
end;

procedure TpvVulkanCommandBuffer.CmdWaitEvents(eventCount:TpvUInt32;const aEvents:PVkEvent;srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;memoryBarrierCount:TpvUInt32;const aMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TpvUInt32;const aBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TpvUInt32;const aImageMemoryBarriers:PVkImageMemoryBarrier);
begin
 fDevice.fDeviceVulkan.CmdWaitEvents(fCommandBufferHandle,eventCount,aEvents,srcStageMask,dstStageMask,memoryBarrierCount,aMemoryBarriers,bufferMemoryBarrierCount,aBufferMemoryBarriers,imageMemoryBarrierCount,aImageMemoryBarriers);
end;

procedure TpvVulkanCommandBuffer.CmdPipelineBarrier(srcStageMask:TVkPipelineStageFlags;dstStageMask:TVkPipelineStageFlags;dependencyFlags:TVkDependencyFlags;memoryBarrierCount:TpvUInt32;const aMemoryBarriers:PVkMemoryBarrier;bufferMemoryBarrierCount:TpvUInt32;const aBufferMemoryBarriers:PVkBufferMemoryBarrier;imageMemoryBarrierCount:TpvUInt32;const aImageMemoryBarriers:PVkImageMemoryBarrier);
begin
 fDevice.fDeviceVulkan.CmdPipelineBarrier(fCommandBufferHandle,srcStageMask,dstStageMask,dependencyFlags,memoryBarrierCount,aMemoryBarriers,bufferMemoryBarrierCount,aBufferMemoryBarriers,imageMemoryBarrierCount,aImageMemoryBarriers);
end;

procedure TpvVulkanCommandBuffer.CmdBeginQuery(queryPool:TVkQueryPool;query:TpvUInt32;flags:TVkQueryControlFlags);
begin
 fDevice.fDeviceVulkan.CmdBeginQuery(fCommandBufferHandle,queryPool,query,flags);
end;

procedure TpvVulkanCommandBuffer.CmdEndQuery(queryPool:TVkQueryPool;query:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdEndQuery(fCommandBufferHandle,queryPool,query);
end;

procedure TpvVulkanCommandBuffer.CmdResetQueryPool(queryPool:TVkQueryPool;firstQuery:TpvUInt32;queryCount:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdResetQueryPool(fCommandBufferHandle,queryPool,firstQuery,queryCount);
end;

procedure TpvVulkanCommandBuffer.CmdWriteTimestamp(pipelineStage:TVkPipelineStageFlagBits;queryPool:TVkQueryPool;query:TpvUInt32);
begin
 fDevice.fDeviceVulkan.CmdWriteTimestamp(fCommandBufferHandle,pipelineStage,queryPool,query);
end;

procedure TpvVulkanCommandBuffer.CmdCopyQueryPoolResults(queryPool:TVkQueryPool;firstQuery:TpvUInt32;queryCount:TpvUInt32;dstBuffer:TVkBuffer;dstOffset:TVkDeviceSize;stride:TVkDeviceSize;flags:TVkQueryResultFlags);
begin
 fDevice.fDeviceVulkan.CmdCopyQueryPoolResults(fCommandBufferHandle,queryPool,firstQuery,queryCount,dstBuffer,dstOffset,stride,flags);
end;

procedure TpvVulkanCommandBuffer.CmdPushConstants(layout:TVkPipelineLayout;stageFlags:TVkShaderStageFlags;offset:TpvUInt32;size:TpvUInt32;const aValues:PVkVoid);
begin
 fDevice.fDeviceVulkan.CmdPushConstants(fCommandBufferHandle,layout,stageFlags,offset,size,aValues);
end;

procedure TpvVulkanCommandBuffer.CmdBeginRenderPass(const aRenderPassBegin:PVkRenderPassBeginInfo;contents:TVkSubpassContents);
begin
 fDevice.fDeviceVulkan.CmdBeginRenderPass(fCommandBufferHandle,aRenderPassBegin,contents);
end;

procedure TpvVulkanCommandBuffer.CmdNextSubpass(contents:TVkSubpassContents);
begin
 fDevice.fDeviceVulkan.CmdNextSubpass(fCommandBufferHandle,contents);
end;

procedure TpvVulkanCommandBuffer.CmdEndRenderPass;
begin
 fDevice.fDeviceVulkan.CmdEndRenderPass(fCommandBufferHandle);
end;

procedure TpvVulkanCommandBuffer.CmdExecuteCommands(commandBufferCount:TpvUInt32;const aCommandBuffers:PVkCommandBuffer);
begin
 fDevice.fDeviceVulkan.CmdExecuteCommands(fCommandBufferHandle,commandBufferCount,aCommandBuffers);
end;

procedure TpvVulkanCommandBuffer.CmdExecute(const aCommandBuffer:TpvVulkanCommandBuffer);
begin
 CmdExecuteCommands(1,@aCommandBuffer.fCommandBufferHandle);
end;

procedure TpvVulkanCommandBuffer.MetaCmdPresentToDrawImageBarrier(const aImage:TpvVulkanImage;const aDoTransitionToColorAttachmentOptimalLayout:boolean=true);
var ImageMemoryBarrier:TVkImageMemoryBarrier;
begin
 FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
 ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
 ImageMemoryBarrier.pNext:=nil;
 ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT);
 ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
 if aDoTransitionToColorAttachmentOptimalLayout then begin
  ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
  ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
 end else begin
  ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
  ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
 end;
 if (fDevice.fPresentQueueFamilyIndex<>fDevice.fGraphicsQueueFamilyIndex) or
    ((assigned(fDevice.fPresentQueue) and assigned(fDevice.fGraphicsQueue)) and
     (fDevice.fPresentQueue<>fDevice.fGraphicsQueue)) then begin
  ImageMemoryBarrier.srcQueueFamilyIndex:=fDevice.fPresentQueueFamilyIndex;
  ImageMemoryBarrier.dstQueueFamilyIndex:=fDevice.fGraphicsQueueFamilyIndex;
 end else begin
  ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
  ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 end;
 ImageMemoryBarrier.image:=aImage.fImageHandle;
 ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
 ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
 ImageMemoryBarrier.subresourceRange.levelCount:=1;
 ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
 ImageMemoryBarrier.subresourceRange.layerCount:=1;
 CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                    TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                    0,
                    0,nil,
                    0,nil,
                    1,@ImageMemoryBarrier);
end;

procedure TpvVulkanCommandBuffer.MetaCmdDrawToPresentImageBarrier(const aImage:TpvVulkanImage;const aDoTransitionToPresentSrcLayout:boolean=true);
var ImageMemoryBarrier:TVkImageMemoryBarrier;
begin
 FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
 ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
 ImageMemoryBarrier.pNext:=nil;
 ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT);
 ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT);
 if aDoTransitionToPresentSrcLayout then begin
  ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
  ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
 end else begin
  ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
  ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
 end;
 if (fDevice.fPresentQueueFamilyIndex<>fDevice.fGraphicsQueueFamilyIndex) or
    ((assigned(fDevice.fPresentQueue) and assigned(fDevice.fGraphicsQueue)) and
     (fDevice.fPresentQueue<>fDevice.fGraphicsQueue)) then begin
  ImageMemoryBarrier.srcQueueFamilyIndex:=fDevice.fGraphicsQueueFamilyIndex;
  ImageMemoryBarrier.dstQueueFamilyIndex:=fDevice.fPresentQueueFamilyIndex;
 end else begin
  ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
  ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
 end;
 ImageMemoryBarrier.image:=aImage.fImageHandle;
 ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
 ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
 ImageMemoryBarrier.subresourceRange.levelCount:=1;
 ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
 ImageMemoryBarrier.subresourceRange.layerCount:=1;
 CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                    TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                    0,
                    0,nil,
                    0,nil,
                    1,@ImageMemoryBarrier);
end;

procedure TpvVulkanCommandBuffer.MetaCmdMemoryBarrier(const aSrcStageMask,aDstStageMask:TVkPipelineStageFlags;const aSrcAccessMask,aDstAccessMask:TVkAccessFlags);
var MemoryBarrier:TVkMemoryBarrier;
begin
 MemoryBarrier.sType:=VK_STRUCTURE_TYPE_MEMORY_BARRIER;;
 MemoryBarrier.pNext:=nil;
 MemoryBarrier.srcAccessMask:=aSrcAccessMask;
 MemoryBarrier.dstAccessMask:=aDstAccessMask;
 CmdPipelineBarrier(aSrcStageMask,
                    aDstStageMask,
                    0,
                    1,@MemoryBarrier,
                    0,nil,
                    0,nil);
end;

procedure TpvVulkanCommandBuffer.Execute(const aQueue:TpvVulkanQueue;const aWaitDstStageFlags:TVkPipelineStageFlags;const aWaitSemaphore:TpvVulkanSemaphore=nil;const aSignalSemaphore:TpvVulkanSemaphore=nil;const aFence:TpvVulkanFence=nil;const aDoWaitAndResetFence:boolean=true);
var SubmitInfo:TVkSubmitInfo;
begin
 if fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin

  FillChar(SubmitInfo,SizeOf(TVkSubmitInfo),#0);
  SubmitInfo.sType:=VK_STRUCTURE_TYPE_SUBMIT_INFO;
  SubmitInfo.pNext:=nil;
  if assigned(aWaitSemaphore) then begin
   SubmitInfo.waitSemaphoreCount:=1;
   SubmitInfo.pWaitSemaphores:=@aWaitSemaphore.fSemaphoreHandle;
   SubmitInfo.pWaitDstStageMask:=@aWaitDstStageFlags;
  end else begin
   SubmitInfo.waitSemaphoreCount:=0;
   SubmitInfo.pWaitSemaphores:=nil;
   SubmitInfo.pWaitDstStageMask:=nil;
  end;
  SubmitInfo.commandBufferCount:=1;
  SubmitInfo.pCommandBuffers:=@fCommandBufferHandle;
  if assigned(aSignalSemaphore) then begin
   SubmitInfo.signalSemaphoreCount:=1;
   SubmitInfo.pSignalSemaphores:=@aSignalSemaphore.fSemaphoreHandle;
  end else begin
   SubmitInfo.signalSemaphoreCount:=0;
   SubmitInfo.pSignalSemaphores:=nil;
  end;

  if assigned(aFence) then begin

   aQueue.Submit(1,@SubmitInfo,aFence);

   if aDoWaitAndResetFence then begin
    aFence.WaitFor;
    aFence.Reset;
   end;

  end else begin

   aQueue.Submit(1,@SubmitInfo,nil);

  end;

 end else begin
  raise EpvVulkanException.Create('Execute called from a non-primary command buffer!');
 end;
end;

constructor TpvVulkanCommandBufferSubmitQueue.Create(const aQueue:TpvVulkanQueue);
begin
 inherited Create;
 fDevice:=aQueue.fDevice;
 fQueue:=aQueue;
 fSubmitInfos:=nil;
 fSubmitInfoWaitSemaphores:=nil;
 fSubmitInfoWaitDstStageFlags:=nil;
 fSubmitInfoSignalSemaphores:=nil;
 fCountSubmitInfos:=0;
end;

destructor TpvVulkanCommandBufferSubmitQueue.Destroy;
begin
 fSubmitInfos:=nil;
 fSubmitInfoWaitSemaphores:=nil;
 fSubmitInfoWaitDstStageFlags:=nil;
 fSubmitInfoSignalSemaphores:=nil;
 fCountSubmitInfos:=0;
 inherited Destroy;
end;

procedure TpvVulkanCommandBufferSubmitQueue.Reset;
begin
 fCountSubmitInfos:=0;
end;
                                                 
procedure TpvVulkanCommandBufferSubmitQueue.QueueSubmit(const aCommandBuffer:TpvVulkanCommandBuffer;const aWaitDstStageFlags:TVkPipelineStageFlags;const aWaitSemaphore:TpvVulkanSemaphore=nil;const aSignalSemaphore:TpvVulkanSemaphore=nil);
var Index:TpvInt32;
    SubmitInfo:PVkSubmitInfo;
begin
 if aCommandBuffer.fLevel=VK_COMMAND_BUFFER_LEVEL_PRIMARY then begin

  Index:=fCountSubmitInfos;
  inc(fCountSubmitInfos);
  if length(fSubmitInfos)<fCountSubmitInfos then begin
   SetLength(fSubmitInfos,fCountSubmitInfos*2);
   SetLength(fSubmitInfoWaitSemaphores,fCountSubmitInfos*2);
   SetLength(fSubmitInfoWaitDstStageFlags,fCountSubmitInfos*2);
   SetLength(fSubmitInfoSignalSemaphores,fCountSubmitInfos*2);
  end;
  SubmitInfo:=@fSubmitInfos[Index];

  FillChar(SubmitInfo^,SizeOf(TVkSubmitInfo),#0);
  SubmitInfo^.sType:=VK_STRUCTURE_TYPE_SUBMIT_INFO;
  SubmitInfo^.pNext:=nil;
  if assigned(aWaitSemaphore) then begin
   SubmitInfo^.waitSemaphoreCount:=1;
   fSubmitInfoWaitSemaphores[Index]:=aWaitSemaphore.fSemaphoreHandle;
   fSubmitInfoWaitDstStageFlags[Index]:=aWaitDstStageFlags;
  end else begin
   SubmitInfo^.waitSemaphoreCount:=0;
   fSubmitInfoWaitSemaphores[Index]:=VK_NULL_HANDLE;
   fSubmitInfoWaitDstStageFlags[Index]:=0;
  end;
  SubmitInfo^.pWaitSemaphores:=nil;
  SubmitInfo^.pWaitDstStageMask:=nil;
  SubmitInfo^.commandBufferCount:=1;
  SubmitInfo^.pCommandBuffers:=@aCommandBuffer.fCommandBufferHandle;
  if assigned(aSignalSemaphore) then begin
   SubmitInfo^.signalSemaphoreCount:=1;
   fSubmitInfoSignalSemaphores[Index]:=aSignalSemaphore.fSemaphoreHandle;
  end else begin
   SubmitInfo^.signalSemaphoreCount:=0;
   fSubmitInfoSignalSemaphores[Index]:=VK_NULL_HANDLE;
  end;
  SubmitInfo^.pSignalSemaphores:=nil;

 end else begin
  raise EpvVulkanException.Create('Execute called from a non-primary command buffer!');
 end;
end;

procedure TpvVulkanCommandBufferSubmitQueue.SubmitQueued(const aFence:TpvVulkanFence=nil;const aDoWaitAndResetFence:boolean=true);
var Index:TpvInt32;
    SubmitInfo:PVkSubmitInfo;
begin

 if fCountSubmitInfos>0 then begin

  for Index:=0 to fCountSubmitInfos-1 do begin
   SubmitInfo:=@fSubmitInfos[Index];
   if SubmitInfo^.waitSemaphoreCount>0 then begin
    SubmitInfo^.pWaitSemaphores:=@fSubmitInfoWaitSemaphores[Index];
    SubmitInfo^.pWaitDstStageMask:=@fSubmitInfoWaitDstStageFlags[Index];
   end else begin
    SubmitInfo^.pWaitSemaphores:=nil;
    SubmitInfo^.pWaitDstStageMask:=nil;
   end;
   if SubmitInfo^.signalSemaphoreCount>0 then begin
    SubmitInfo^.pSignalSemaphores:=@fSubmitInfoSignalSemaphores[Index];
   end else begin
    SubmitInfo^.pSignalSemaphores:=nil;
   end;
  end;

  if assigned(aFence) then begin

   fQueue.Submit(fCountSubmitInfos,@fSubmitInfos[0],aFence);

   if aDoWaitAndResetFence then begin
    aFence.WaitFor;
    aFence.Reset;
   end;

  end else begin

   fQueue.Submit(fCountSubmitInfos,@fSubmitInfos[0],nil);

  end;

 end else begin

  if aDoWaitAndResetFence then begin
   aFence.Reset;
  end;

 end;

end;

constructor TpvVulkanRenderPass.Create(const aDevice:TpvVulkanDevice);
begin
 inherited Create;

 fDevice:=aDevice;

 fRenderPassHandle:=VK_NULL_HANDLE;

 fAttachmentDescriptions:=nil;
 fCountAttachmentDescriptions:=0;

 fAttachmentReferences:=nil;
 fCountAttachmentReferences:=0;

 fRenderPassSubpassDescriptions:=nil;
 fSubpassDescriptions:=nil;
 fCountSubpassDescriptions:=0;

 fSubpassDependencies:=nil;
 fCountSubpassDependencies:=0;

 fClearValues:=nil;

end;

destructor TpvVulkanRenderPass.Destroy;
begin
 if fRenderPassHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyRenderPass(fDevice.fDeviceHandle,fRenderPassHandle,fDevice.fAllocationCallbacks);
  fRenderPassHandle:=VK_NULL_HANDLE;
 end;
 SetLength(fAttachmentDescriptions,0);
 SetLength(fAttachmentReferences,0);
 SetLength(fRenderPassSubpassDescriptions,0);
 SetLength(fSubpassDescriptions,0);
 SetLength(fSubpassDependencies,0);
 SetLength(fClearValues,0);
 inherited Destroy;
end;

function TpvVulkanRenderPass.GetClearValue(const Index:TpvUInt32):PVkClearValue;
begin
 result:=@fClearValues[Index];
end;

function TpvVulkanRenderPass.AddAttachmentDescription(const aFlags:TVkAttachmentDescriptionFlags;
                                                      const aFormat:TVkFormat;
                                                      const aSamples:TVkSampleCountFlagBits;
                                                      const aLoadOp:TVkAttachmentLoadOp;
                                                      const aStoreOp:TVkAttachmentStoreOp;
                                                      const aStencilLoadOp:TVkAttachmentLoadOp;
                                                      const aStencilStoreOp:TVkAttachmentStoreOp;
                                                      const aInitialLayout:TVkImageLayout;
                                                      const aFinalLayout:TVkImageLayout):TpvUInt32;
var AttachmentDescription:PVkAttachmentDescription;
begin
 result:=fCountAttachmentDescriptions;
 inc(fCountAttachmentDescriptions);
 if fCountAttachmentDescriptions>length(fAttachmentDescriptions) then begin
  SetLength(fAttachmentDescriptions,fCountAttachmentDescriptions*2);
 end;
 AttachmentDescription:=@fAttachmentDescriptions[result];
 AttachmentDescription^.flags:=aFlags;
 AttachmentDescription^.format:=aFormat;
 AttachmentDescription^.samples:=aSamples;
 AttachmentDescription^.loadOp:=aLoadOp;
 AttachmentDescription^.storeOp:=aStoreOp;
 AttachmentDescription^.stencilLoadOp:=aStencilLoadOp;
 AttachmentDescription^.stencilStoreOp:=aStencilStoreOp;
 AttachmentDescription^.initialLayout:=aInitialLayout;
 AttachmentDescription^.finalLayout:=aFinalLayout;
end;

function TpvVulkanRenderPass.AddAttachmentReference(const aAttachment:TpvUInt32;
                                                    const aLayout:TVkImageLayout):TpvUInt32;
var AttachmentReference:PVkAttachmentReference;
begin
 result:=fCountAttachmentReferences;
 inc(fCountAttachmentReferences);
 if fCountAttachmentReferences>length(fAttachmentReferences) then begin
  SetLength(fAttachmentReferences,fCountAttachmentReferences*2);
 end;
 AttachmentReference:=@fAttachmentReferences[result];
 AttachmentReference^.attachment:=aAttachment;
 AttachmentReference^.layout:=aLayout;
end;

function TpvVulkanRenderPass.AddSubpassDescription(const aFlags:TVkSubpassDescriptionFlags;
                                                   const aPipelineBindPoint:TVkPipelineBindPoint;
                                                   const aInputAttachments:array of TpvInt32;
                                                   const aColorAttachments:array of TpvInt32;
                                                   const aResolveAttachments:array of TpvInt32;
                                                   const aDepthStencilAttachment:TpvInt32;
                                                   const aPreserveAttachments:array of TpvUInt32):TpvUInt32;
var RenderPassSubpassDescription:PpvVulkanRenderPassSubpassDescription;
begin
 result:=fCountSubpassDescriptions;
 inc(fCountSubpassDescriptions);
 if fCountSubpassDescriptions>length(fRenderPassSubpassDescriptions) then begin
  SetLength(fRenderPassSubpassDescriptions,fCountSubpassDescriptions*2);
 end;
 RenderPassSubpassDescription:=@fRenderPassSubpassDescriptions[result];
 RenderPassSubpassDescription^.Flags:=aFlags;
 RenderPassSubpassDescription^.PipelineBindPoint:=aPipelineBindPoint;
 begin
  SetLength(RenderPassSubpassDescription^.InputAttachments,length(aInputAttachments));
  if length(aInputAttachments)>0 then begin
   Move(aInputAttachments[0],RenderPassSubpassDescription^.InputAttachments[0],length(aInputAttachments)*SizeOf(TpvInt32));
  end;
 end;
 begin
  SetLength(RenderPassSubpassDescription^.ColorAttachments,length(aColorAttachments));
  if length(aColorAttachments)>0 then begin
   Move(aColorAttachments[0],RenderPassSubpassDescription^.ColorAttachments[0],length(aColorAttachments)*SizeOf(TpvInt32));
  end;
 end;
 begin
  SetLength(RenderPassSubpassDescription^.ResolveAttachments,length(aResolveAttachments));
  if length(aResolveAttachments)>0 then begin
   Move(aResolveAttachments[0],RenderPassSubpassDescription^.ResolveAttachments[0],length(aResolveAttachments)*SizeOf(TpvInt32));
  end;
 end;
 RenderPassSubpassDescription^.DepthStencilAttachment:=aDepthStencilAttachment;
 begin
  SetLength(RenderPassSubpassDescription^.PreserveAttachments,length(aPreserveAttachments));
  if length(aPreserveAttachments)>0 then begin
   Move(aPreserveAttachments[0],RenderPassSubpassDescription^.PreserveAttachments[0],length(aPreserveAttachments)*SizeOf(TpvUInt32));
  end;
 end;
end;

function TpvVulkanRenderPass.AddSubpassDependency(const aSrcSubpass:TpvUInt32;
                                                  const aDstSubpass:TpvUInt32;
                                                  const aSrcStageMask:TVkPipelineStageFlags;
                                                  const aDstStageMask:TVkPipelineStageFlags;
                                                  const aSrcAccessMask:TVkAccessFlags;
                                                  const aDstAccessMask:TVkAccessFlags;
                                                  const aDependencyFlags:TVkDependencyFlags):TpvUInt32;
var SubpassDependency:PVkSubpassDependency;
begin
 result:=fCountSubpassDependencies;
 inc(fCountSubpassDependencies);
 if fCountSubpassDependencies>length(fSubpassDependencies) then begin
  SetLength(fSubpassDependencies,fCountSubpassDependencies*2);
 end;
 SubpassDependency:=@fSubpassDependencies[result];
 SubpassDependency^.srcSubpass:=aSrcSubpass;
 SubpassDependency^.dstSubpass:=aDstSubpass;
 SubpassDependency^.srcStageMask:=aSrcStageMask;
 SubpassDependency^.dstStageMask:=aDstStageMask;
 SubpassDependency^.srcAccessMask:=aSrcAccessMask;
 SubpassDependency^.dstAccessMask:=aDstAccessMask;
 SubpassDependency^.DependencyFlags:=aDependencyFlags;
end;

procedure TpvVulkanRenderPass.Initialize;
var Index,SubIndex,fCountClearValues:TpvInt32;
    AttachmentDescription:PVkAttachmentDescription;
    SubpassDescription:PVkSubpassDescription;
    RenderPassSubpassDescription:PpvVulkanRenderPassSubpassDescription;
    ClearValue:PVkClearValue;
    RenderPassCreateInfo:TVkRenderPassCreateInfo;
begin

 FillChar(RenderPassCreateInfo,Sizeof(TVkRenderPassCreateInfo),#0);
 RenderPassCreateInfo.sType:=VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;

 SetLength(fAttachmentDescriptions,fCountAttachmentDescriptions);
 SetLength(fAttachmentReferences,fCountAttachmentReferences);
 SetLength(fRenderPassSubpassDescriptions,fCountSubpassDescriptions);
 SetLength(fSubpassDescriptions,fCountSubpassDescriptions);
 SetLength(fSubpassDependencies,fCountSubpassDependencies);

 fCountClearValues:=0;
 for Index:=0 to fCountAttachmentDescriptions-1 do begin
  AttachmentDescription:=@fAttachmentDescriptions[Index];
  if AttachmentDescription^.loadOp in [VK_ATTACHMENT_LOAD_OP_CLEAR] then begin
   fCountClearValues:=Max(fCountClearValues,Index+1);
  end;
 end;
 SetLength(fClearValues,fCountClearValues);
 for Index:=0 to fCountClearValues-1 do begin
  AttachmentDescription:=@fAttachmentDescriptions[Index];
  ClearValue:=@fClearValues[Index];
  case AttachmentDescription^.format of
   VK_FORMAT_D32_SFLOAT_S8_UINT,
   VK_FORMAT_D32_SFLOAT,
   VK_FORMAT_D24_UNORM_S8_UINT,
   VK_FORMAT_D16_UNORM_S8_UINT,
   VK_FORMAT_D16_UNORM:begin
    ClearValue^.depthStencil.depth:=1.0;
    ClearValue^.depthStencil.stencil:=0;
   end;
   else begin
    ClearValue^.color.uint32[0]:=0;
    ClearValue^.color.uint32[1]:=0;
    ClearValue^.color.uint32[2]:=0;
    ClearValue^.color.uint32[3]:=0;
   end;
  end;
 end;

 if fCountAttachmentDescriptions>0 then begin
  RenderPassCreateInfo.attachmentCount:=fCountAttachmentDescriptions;
  RenderPassCreateInfo.pAttachments:=@fAttachmentDescriptions[0];
 end;

 if fCountSubpassDescriptions>0 then begin
  for Index:=0 to fCountSubpassDescriptions-1 do begin
   SubpassDescription:=@fSubpassDescriptions[Index];
   RenderPassSubpassDescription:=@fRenderPassSubpassDescriptions[Index];
   FillChar(SubpassDescription^,SizeOf(TVkSubpassDescription),#0);
   SubpassDescription^.flags:=RenderPassSubpassDescription^.Flags;
   SubpassDescription^.pipelineBindPoint:=RenderPassSubpassDescription^.PipelineBindPoint;
   begin
    SubpassDescription^.inputAttachmentCount:=length(RenderPassSubpassDescription^.InputAttachments);
    if SubpassDescription^.inputAttachmentCount>0 then begin
     SetLength(RenderPassSubpassDescription^.aInputAttachments,SubpassDescription^.inputAttachmentCount);
     for SubIndex:=0 to length(RenderPassSubpassDescription^.InputAttachments)-1 do begin
      RenderPassSubpassDescription^.aInputAttachments[SubIndex]:=fAttachmentReferences[RenderPassSubpassDescription^.InputAttachments[SubIndex]];
     end;
     SubpassDescription^.pInputAttachments:=@RenderPassSubpassDescription^.aInputAttachments[0];
    end;
   end;
   begin
    SubpassDescription^.ColorAttachmentCount:=length(RenderPassSubpassDescription^.ColorAttachments);
    if SubpassDescription^.ColorAttachmentCount>0 then begin
     SetLength(RenderPassSubpassDescription^.aColorAttachments,SubpassDescription^.ColorAttachmentCount);
     for SubIndex:=0 to length(RenderPassSubpassDescription^.ColorAttachments)-1 do begin
      RenderPassSubpassDescription^.aColorAttachments[SubIndex]:=fAttachmentReferences[RenderPassSubpassDescription^.ColorAttachments[SubIndex]];
     end;
     SubpassDescription^.pColorAttachments:=@RenderPassSubpassDescription^.aColorAttachments[0];
    end;
   end;
   begin
    if (SubpassDescription^.ColorAttachmentCount>0) and
       (SubpassDescription^.ColorAttachmentCount=TpvUInt32(length(RenderPassSubpassDescription^.ResolveAttachments))) then begin
     SetLength(RenderPassSubpassDescription^.aResolveAttachments,SubpassDescription^.ColorAttachmentCount);
     for SubIndex:=0 to length(RenderPassSubpassDescription^.ResolveAttachments)-1 do begin
      RenderPassSubpassDescription^.aResolveAttachments[SubIndex]:=fAttachmentReferences[RenderPassSubpassDescription^.ResolveAttachments[SubIndex]];
     end;
     SubpassDescription^.pResolveAttachments:=@RenderPassSubpassDescription^.aResolveAttachments[0];
    end;
   end;
   if RenderPassSubpassDescription^.DepthStencilAttachment>=0 then begin
    SubpassDescription^.pDepthStencilAttachment:=@fAttachmentReferences[RenderPassSubpassDescription^.DepthStencilAttachment];
   end;
   begin
    SubpassDescription^.PreserveAttachmentCount:=length(RenderPassSubpassDescription^.PreserveAttachments);
    if SubpassDescription^.PreserveAttachmentCount>0 then begin
     SubpassDescription^.pPreserveAttachments:=@RenderPassSubpassDescription^.PreserveAttachments[0];
    end;
   end;
  end;
  RenderPassCreateInfo.subpassCount:=fCountSubpassDescriptions;
  RenderPassCreateInfo.pSubpasses:=@fSubpassDescriptions[0];
 end;

 if fCountSubpassDependencies>0 then begin
  RenderPassCreateInfo.dependencyCount:=fCountSubpassDependencies;
  RenderPassCreateInfo.pDependencies:=@fSubpassDependencies[0];
 end;
 
 HandleResultCode(fDevice.fDeviceVulkan.CreateRenderPass(fDevice.fDeviceHandle,@RenderPassCreateInfo,fDevice.fAllocationCallbacks,@fRenderPassHandle));

end;

procedure TpvVulkanRenderPass.BeginRenderPass(const aCommandBuffer:TpvVulkanCommandBuffer;
                                              const aFrameBuffer:TpvVulkanFrameBuffer;
                                              const aSubpassContents:TVkSubpassContents;
                                              const aOffsetX,aOffsetY,aWidth,aHeight:TpvUInt32);
var RenderPassBeginInfo:TVkRenderPassBeginInfo;
begin
 FillChar(RenderPassBeginInfo,SizeOf(TVkRenderPassBeginInfo),#0);
 RenderPassBeginInfo.sType:=VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;
 RenderPassBeginInfo.renderPass:=fRenderPassHandle;
 RenderPassBeginInfo.framebuffer:=aFrameBuffer.fFrameBufferHandle;
 RenderPassBeginInfo.renderArea.offset.x:=aOffsetX;
 RenderPassBeginInfo.renderArea.offset.y:=aOffsetY;
 RenderPassBeginInfo.renderArea.extent.width:=aWidth;
 RenderPassBeginInfo.renderArea.extent.height:=aHeight;
 RenderPassBeginInfo.clearValueCount:=length(fClearValues);
 if RenderPassBeginInfo.clearValueCount>0 then begin
  RenderPassBeginInfo.pClearValues:=@fClearValues[0];
 end;
 aCommandBuffer.CmdBeginRenderPass(@RenderPassBeginInfo,aSubpassContents);
end;

procedure TpvVulkanRenderPass.EndRenderPass(const aCommandBuffer:TpvVulkanCommandBuffer);
begin
 aCommandBuffer.CmdEndRenderPass;
end;

constructor TpvVulkanSampler.Create(const aDevice:TpvVulkanDevice;
                                    const aSampler:TVkSampler;
                                    const aDoDestroy:boolean=true);
begin

 inherited Create;

 fDevice:=aDevice;

 fSamplerHandle:=aSampler;

 fDoDestroy:=aDoDestroy;

end;

constructor TpvVulkanSampler.Create(const aDevice:TpvVulkanDevice;
                                    const aMagFilter:TVkFilter;
                                    const aMinFilter:TVkFilter;
                                    const aMipmapMode:TVkSamplerMipmapMode;
                                    const aAddressModeU:TVkSamplerAddressMode;
                                    const aAddressModeV:TVkSamplerAddressMode;
                                    const aAddressModeW:TVkSamplerAddressMode;
                                    const aMipLodBias:TpvFloat;
                                    const aAnisotropyEnable:boolean;
                                    const aMaxAnisotropy:TpvFloat;
                                    const aCompareEnable:boolean;
                                    const aCompareOp:TVkCompareOp;
                                    const aMinLod:TpvFloat;
                                    const aMaxLod:TpvFloat;
                                    const aBorderColor:TVkBorderColor;
                                    const aUnnormalizedCoordinates:boolean);
var SamplerCreateInfo:TVkSamplerCreateInfo;
begin

 inherited Create;

 fDevice:=aDevice;

 fSamplerHandle:=VK_NULL_HANDLE;

 fDoDestroy:=true;

 FillChar(SamplerCreateInfo,SizeOf(TVkSamplerCreateInfo),#0);
 SamplerCreateInfo.sType:=VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO;
 SamplerCreateInfo.pNext:=nil;
 SamplerCreateInfo.flags:=0;
 SamplerCreateInfo.magFilter:=aMagFilter;
 SamplerCreateInfo.minFilter:=aMinFilter;
 SamplerCreateInfo.mipmapMode:=aMipmapMode;
 SamplerCreateInfo.addressModeU:=aAddressModeU;
 SamplerCreateInfo.addressModeV:=aAddressModeV;
 SamplerCreateInfo.addressModeW:=aAddressModeW;
 SamplerCreateInfo.mipLodBias:=aMipLodBias;
 if aAnisotropyEnable then begin
  SamplerCreateInfo.anisotropyEnable:=VK_TRUE;
 end else begin
  SamplerCreateInfo.anisotropyEnable:=VK_FALSE;
 end;
 SamplerCreateInfo.maxAnisotropy:=aMaxAnisotropy;
 if aCompareEnable then begin
  SamplerCreateInfo.compareEnable:=VK_TRUE;
 end else begin
  SamplerCreateInfo.compareEnable:=VK_FALSE;
 end;
 SamplerCreateInfo.compareOp:=aCompareOp;
 SamplerCreateInfo.minLod:=aMinLod;
 SamplerCreateInfo.maxLod:=aMaxLod;
 SamplerCreateInfo.borderColor:=aBorderColor;
 if aUnnormalizedCoordinates then begin
  SamplerCreateInfo.unnormalizedCoordinates:=VK_TRUE;
 end else begin
  SamplerCreateInfo.unnormalizedCoordinates:=VK_FALSE;
 end;

 HandleResultCode(fDevice.fDeviceVulkan.CreateSampler(fDevice.fDeviceHandle,@SamplerCreateInfo,fDevice.fAllocationCallbacks,@fSamplerHandle));

end;

destructor TpvVulkanSampler.Destroy;
begin
 if fSamplerHandle<>VK_NULL_HANDLE then begin
  if fDoDestroy then begin
   fDevice.fDeviceVulkan.DestroySampler(fDevice.fDeviceHandle,fSamplerHandle,fDevice.fAllocationCallbacks);
  end;
  fSamplerHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanImage.Create(const aDevice:TpvVulkanDevice;
                                  const aImage:TVkImage;
                                  const aImageView:TpvVulkanImageView=nil;
                                  const aDoDestroy:boolean=true);
begin

 inherited Create;

 fDevice:=aDevice;

 fImageHandle:=aImage;

 fImageView:=aImageView;

 fDoDestroy:=aDoDestroy;

end;

constructor TpvVulkanImage.Create(const aDevice:TpvVulkanDevice;
                                  const aFlags:TVkImageCreateFlags;
                                  const aImageType:TVkImageType;
                                  const aFormat:TVkFormat;
                                  const aExtentWidth:TpvUInt32;
                                  const aExtentHeight:TpvUInt32;
                                  const aExtentDepth:TpvUInt32;
                                  const aMipLevels:TpvUInt32;
                                  const aArrayLayers:TpvUInt32;
                                  const aSamples:TVkSampleCountFlagBits;
                                  const aTiling:TVkImageTiling;
                                  const aUsage:TVkImageUsageFlags;
                                  const aSharingMode:TVkSharingMode;
                                  const aQueueFamilyIndexCount:TpvUInt32;
                                  const aQueueFamilyIndices:PpvUInt32;
                                  const aInitialLayout:TVkImageLayout);
var ImageCreateInfo:TVkImageCreateInfo;
begin

 inherited Create;

 fDevice:=aDevice;

 fImageHandle:=VK_NULL_HANDLE;

 fImageView:=nil;

 fDoDestroy:=true;

 FillChar(ImageCreateInfo,SizeOf(TVkImageCreateInfo),#0);
 ImageCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
 ImageCreateInfo.pNext:=nil;
 ImageCreateInfo.flags:=aFlags;
 ImageCreateInfo.imageType:=aImageType;
 ImageCreateInfo.format:=aFormat;
 ImageCreateInfo.extent.width:=aExtentWidth;
 ImageCreateInfo.extent.height:=aExtentHeight;
 ImageCreateInfo.extent.depth:=aExtentDepth;
 ImageCreateInfo.mipLevels:=aMipLevels;
 ImageCreateInfo.arrayLayers:=aArrayLayers;
 ImageCreateInfo.samples:=aSamples;
 ImageCreateInfo.tiling:=aTiling;
 ImageCreateInfo.usage:=aUsage;
 ImageCreateInfo.sharingMode:=aSharingMode;
 ImageCreateInfo.queueFamilyIndexCount:=aQueueFamilyIndexCount;
 ImageCreateInfo.pQueueFamilyIndices:=TpvPointer(aQueueFamilyIndices);
 ImageCreateInfo.initialLayout:=aInitialLayout;

 HandleResultCode(fDevice.fDeviceVulkan.CreateImage(fDevice.fDeviceHandle,@ImageCreateInfo,fDevice.fAllocationCallbacks,@fImageHandle));

end;

constructor TpvVulkanImage.Create(const aDevice:TpvVulkanDevice;
                                  const aFlags:TVkImageCreateFlags;
                                  const aImageType:TVkImageType;
                                  const aFormat:TVkFormat;
                                  const aExtentWidth:TpvUInt32;
                                  const aExtentHeight:TpvUInt32;
                                  const aExtentDepth:TpvUInt32;
                                  const aMipLevels:TpvUInt32;
                                  const aArrayLayers:TpvUInt32;
                                  const aSamples:TVkSampleCountFlagBits;
                                  const aTiling:TVkImageTiling;
                                  const aUsage:TVkImageUsageFlags;
                                  const aSharingMode:TVkSharingMode;
                                  const aQueueFamilyIndices:array of TpvUInt32;
                                  const aInitialLayout:TVkImageLayout);
var ImageCreateInfo:TVkImageCreateInfo;
begin

 inherited Create;

 fDevice:=aDevice;

 fImageHandle:=VK_NULL_HANDLE;

 fImageView:=nil;

 fDoDestroy:=true;

 FillChar(ImageCreateInfo,SizeOf(TVkImageCreateInfo),#0);
 ImageCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
 ImageCreateInfo.pNext:=nil;
 ImageCreateInfo.flags:=aFlags;
 ImageCreateInfo.imageType:=aImageType;
 ImageCreateInfo.format:=aFormat;
 ImageCreateInfo.extent.width:=aExtentWidth;
 ImageCreateInfo.extent.height:=aExtentHeight;
 ImageCreateInfo.extent.depth:=aExtentDepth;
 ImageCreateInfo.mipLevels:=aMipLevels;
 ImageCreateInfo.arrayLayers:=aArrayLayers;
 ImageCreateInfo.samples:=aSamples;
 ImageCreateInfo.tiling:=aTiling;
 ImageCreateInfo.usage:=aUsage;
 ImageCreateInfo.sharingMode:=aSharingMode;
 ImageCreateInfo.queueFamilyIndexCount:=length(aQueueFamilyIndices);
 if ImageCreateInfo.queueFamilyIndexCount>0 then begin
  ImageCreateInfo.pQueueFamilyIndices:=@aQueueFamilyIndices[0];
 end else begin
  ImageCreateInfo.pQueueFamilyIndices:=nil;
 end;
 ImageCreateInfo.initialLayout:=aInitialLayout;

 HandleResultCode(fDevice.fDeviceVulkan.CreateImage(fDevice.fDeviceHandle,@ImageCreateInfo,fDevice.fAllocationCallbacks,@fImageHandle));

end;

destructor TpvVulkanImage.Destroy;
begin
 if assigned(fImageView) then begin
  if fImageView.fImage=self then begin
   fImageView.fImage:=nil;
  end;
  fImageView:=nil;
 end;
 if fImageHandle<>VK_NULL_HANDLE then begin
  if fDoDestroy then begin
   fDevice.fDeviceVulkan.DestroyImage(fDevice.fDeviceHandle,fImageHandle,fDevice.fAllocationCallbacks);
  end;
  fImageHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

procedure TpvVulkanImage.SetLayout(const aAspectMask:TVkImageAspectFlags;
                                   const aOldImageLayout:TVkImageLayout;
                                   const aNewImageLayout:TVkImageLayout;
                                   const aRange:PVkImageSubresourceRange;
                                   const aCommandBuffer:TpvVulkanCommandBuffer;
                                   const aQueue:TpvVulkanQueue=nil;
                                   const aFence:TpvVulkanFence=nil;
                                   const aBeginAndExecuteCommandBuffer:boolean=false;
                                   const aSrcQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED);
                                   const aDstQueueFamilyIndex:TVkQueue=TVkQueue(VK_QUEUE_FAMILY_IGNORED));
begin
 VulkanSetImageLayout(fImageHandle,
                      aAspectMask,
                      aOldImageLayout,
                      aNewImageLayout,
                      aRange,
                      aCommandBuffer,
                      aQueue,
                      aFence,
                      aBeginAndExecuteCommandBuffer,
                      aSrcQueueFamilyIndex,
                      aDstQueueFamilyIndex);
end;

constructor TpvVulkanImageView.Create(const aDevice:TpvVulkanDevice;
                                      const aImageView:TVkImageView;
                                      const aImage:TpvVulkanImage=nil);
begin

 inherited Create;

 fDevice:=aDevice;

 fImageViewHandle:=aImageView;

 fImage:=aImage;

end;

constructor TpvVulkanImageView.Create(const aDevice:TpvVulkanDevice;
                                      const aImage:TpvVulkanImage;
                                      const aImageViewType:TVkImageViewType;
                                      const aFormat:TvkFormat;
                                      const aComponentRed:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                                      const aComponentGreen:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                                      const aComponentBlue:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                                      const aComponentAlpha:TVkComponentSwizzle=VK_COMPONENT_SWIZZLE_IDENTITY;
                                      const aImageAspectFlags:TVkImageAspectFlags=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
                                      const aBaseMipLevel:TpvUInt32=0;
                                      const aCountMipMapLevels:TpvUInt32=1;
                                      const aBaseArrayLayer:TpvUInt32=1;
                                      const aCountArrayLayers:TpvUInt32=0);
var ImageViewCreateInfo:TVkImageViewCreateInfo;
begin

 inherited Create;

 fDevice:=aDevice;

 fImage:=aImage;

 fImageViewHandle:=VK_NULL_HANDLE;

 FillChar(ImageViewCreateInfo,SizeOf(TVkImageViewCreateInfo),#0);
 ImageViewCreateInfo.sType:=VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
 ImageViewCreateInfo.pNext:=nil;
 ImageViewCreateInfo.flags:=0;
 ImageViewCreateInfo.image:=aImage.fImageHandle;
 ImageViewCreateInfo.viewType:=aImageViewType;
 ImageViewCreateInfo.format:=aFormat;
 ImageViewCreateInfo.components.r:=aComponentRed;
 ImageViewCreateInfo.components.g:=aComponentGreen;
 ImageViewCreateInfo.components.b:=aComponentBlue;
 ImageViewCreateInfo.components.a:=aComponentAlpha;
 ImageViewCreateInfo.subresourceRange.aspectMask:=aImageAspectFlags;
 ImageViewCreateInfo.subresourceRange.baseMipLevel:=aBaseMipLevel;
 ImageViewCreateInfo.subresourceRange.levelCount:=aCountMipMapLevels;
 ImageViewCreateInfo.subresourceRange.baseArrayLayer:=aBaseArrayLayer;
 ImageViewCreateInfo.subresourceRange.layerCount:=aCountArrayLayers;

 HandleResultCode(fDevice.fDeviceVulkan.CreateImageView(fDevice.fDeviceHandle,@ImageViewCreateInfo,fDevice.fAllocationCallbacks,@fImageViewHandle));

end;

destructor TpvVulkanImageView.Destroy;
begin
 if assigned(fImage) then begin
  if fImage.fImageView=self then begin
   fImage.fImageView:=nil;
  end;
  fImage:=nil;
 end;
 if fImageViewHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyImageView(fDevice.fDeviceHandle,fImageViewHandle,fDevice.fAllocationCallbacks);
  fImageViewHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanFrameBufferAttachment.Create(const aDevice:TpvVulkanDevice;
                                                  const aGraphicsQueue:TpvVulkanQueue;
                                                  const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                                  const aGraphicsCommandBufferFence:TpvVulkanFence;
                                                  const aWidth:TpvUInt32;
                                                  const aHeight:TpvUInt32;
                                                  const aFormat:TVkFormat;
                                                  const aUsage:TVkBufferUsageFlags);
var MemoryRequirements:TVkMemoryRequirements;
    AspectMask:TVkImageAspectFlags;
    ImageLayout:TVkImageLayout;
begin
 inherited Create;

 fDevice:=aDevice;

 fWidth:=aWidth;

 fHeight:=aHeight;

 fFormat:=aFormat;

 fImage:=nil;

 fImageView:=nil;

 fMemoryBlock:=nil;

 fDoDestroy:=true;

 if (aUsage and TVkBufferUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT))<>0 then begin
  AspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  ImageLayout:=VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
 end else if (aUsage and TVkBufferUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT))<>0 then begin
  if fFormat in [VK_FORMAT_D32_SFLOAT_S8_UINT,VK_FORMAT_D24_UNORM_S8_UINT,VK_FORMAT_D16_UNORM_S8_UINT] then begin
   AspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT) or TVkImageAspectFlags(VK_IMAGE_ASPECT_STENCIL_BIT);
  end else begin
   AspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_DEPTH_BIT);
  end;
  ImageLayout:=VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
 end else begin
  raise EpvVulkanException.Create('Invalid frame buffer attachment');
 end;

 try

  fImage:=TpvVulkanImage.Create(fDevice,
                              0,
                              VK_IMAGE_TYPE_2D,
                              fFormat,
                              aWidth,
                              aHeight,
                              1,
                              1,
                              1,
                              VK_SAMPLE_COUNT_1_BIT,
                              VK_IMAGE_TILING_OPTIMAL,
                              aUsage {or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT)},
                              VK_SHARING_MODE_EXCLUSIVE,
                              [],
                              VK_IMAGE_LAYOUT_UNDEFINED);

  fDevice.fDeviceVulkan.GetImageMemoryRequirements(fDevice.fDeviceHandle,fImage.fImageHandle,@MemoryRequirements);

  fMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock([],
                                                           MemoryRequirements.size,
                                                           MemoryRequirements.alignment,
                                                           MemoryRequirements.memoryTypeBits,
                                                           TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                           0,
                                                           0,
                                                           0,
                                                           0,
                                                           0,
                                                           vdmatImageOptimal);
  if not assigned(fMemoryBlock) then begin
   raise EpvVulkanMemoryAllocationException.Create('Memory for frame buffer attachment couldn''t be allocated!');
  end;

  HandleResultCode(fDevice.fDeviceVulkan.BindImageMemory(fDevice.fDeviceHandle,fImage.fImageHandle,fMemoryBlock.fMemoryChunk.fMemoryHandle,fMemoryBlock.fOffset));

  if (aUsage and TVkBufferUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT))<>0 then begin
   fImage.SetLayout(AspectMask,
                    VK_IMAGE_LAYOUT_UNDEFINED,
                    VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL,
                    nil,
                    aGraphicsCommandBuffer,
                    aGraphicsQueue,
                    aGraphicsCommandBufferFence,
                    true);
  end else begin
   fImage.SetLayout(AspectMask,
                    VK_IMAGE_LAYOUT_UNDEFINED,
                    ImageLayout,
                    nil,
                    aGraphicsCommandBuffer,
                    aGraphicsQueue,
                    aGraphicsCommandBufferFence,
                    true);
  end;
          
  fImageView:=TpvVulkanImageView.Create(fDevice,
                                      fImage,
                                      VK_IMAGE_VIEW_TYPE_2D,
                                      fFormat,
                                      VK_COMPONENT_SWIZZLE_IDENTITY,
                                      VK_COMPONENT_SWIZZLE_IDENTITY,
                                      VK_COMPONENT_SWIZZLE_IDENTITY,
                                      VK_COMPONENT_SWIZZLE_IDENTITY,
                                      AspectMask,
                                      0,
                                      1,
                                      0,
                                      1);

  fImage.fImageView:=fImageView;

 except

  FreeAndNil(fImageView);

  FreeAndNil(fImage);

  if assigned(fMemoryBlock) then begin
   fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
   fMemoryBlock:=nil;
  end;

  raise;

 end;
end;

constructor TpvVulkanFrameBufferAttachment.Create(const aDevice:TpvVulkanDevice;
                                                  const aImage:TpvVulkanImage;
                                                  const aImageView:TpvVulkanImageView;
                                                  const aWidth:TpvUInt32;
                                                  const aHeight:TpvUInt32;
                                                  const aFormat:TVkFormat;
                                                  const aDoDestroy:boolean=true);
begin

 inherited Create;

 fDevice:=aDevice;

 fWidth:=aWidth;

 fHeight:=aHeight;

 fFormat:=aFormat;

 fImage:=aImage;

 fImageView:=aImageView;

 fMemoryBlock:=nil;

 fDoDestroy:=aDoDestroy;

end;

destructor TpvVulkanFrameBufferAttachment.Destroy;
begin

 if fDoDestroy then begin

  FreeAndNil(fImageView);

  FreeAndNil(fImage);

  if assigned(fMemoryBlock) then begin
   fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
   fMemoryBlock:=nil;
  end;

 end else begin

  fImageView:=nil;

  fImage:=nil;

  fMemoryBlock:=nil;

 end;

 inherited Destroy;

end;

constructor TpvVulkanFrameBuffer.Create(const aDevice:TpvVulkanDevice;
                                        const aRenderPass:TpvVulkanRenderPass;
                                        const aWidth:TpvUInt32;
                                        const aHeight:TpvUInt32;
                                        const aLayers:TpvUInt32);
begin

 inherited Create;

 fDevice:=aDevice;

 fFrameBufferHandle:=VK_NULL_HANDLE;

 fFrameBufferAttachments:=nil;

 fFrameBufferAttachmentImageViews:=nil;

 fCountFrameBufferAttachments:=0;

 fRenderPass:=aRenderPass;

 fWidth:=aWidth;

 fHeight:=aHeight;

 fLayers:=aLayers;

 fDoDestroy:=true;

end;

constructor TpvVulkanFrameBuffer.Create(const aDevice:TpvVulkanDevice;
                                        const aRenderPass:TpvVulkanRenderPass;
                                        const aWidth:TpvUInt32;
                                        const aHeight:TpvUInt32;
                                        const aLayers:TpvUInt32;
                                        const aFrameBufferAttachments:array of TpvVulkanFrameBufferAttachment;
                                        const aDoDestroyAttachments:boolean=true);
begin

 inherited Create;

 fDevice:=aDevice;

 fFrameBufferHandle:=VK_NULL_HANDLE;

 fFrameBufferAttachments:=nil;

 fFrameBufferAttachmentImageViews:=nil;

 fCountFrameBufferAttachments:=length(aFrameBufferAttachments);

 SetLength(fFrameBufferAttachments,fCountFrameBufferAttachments);

 if fCountFrameBufferAttachments>0 then begin
  Move(aFrameBufferAttachments[0],fFrameBufferAttachments[0],fCountFrameBufferAttachments*SizeOf(TpvVulkanFrameBufferAttachment));
 end;

 fRenderPass:=aRenderPass;

 fWidth:=aWidth;

 fHeight:=aHeight;

 fLayers:=aLayers;

 fDoDestroy:=true;

 fDoDestroyAttachments:=aDoDestroyAttachments;

 Initialize;

end;                                      

constructor TpvVulkanFrameBuffer.Create(const aDevice:TpvVulkanDevice;
                                        const aRenderPass:TpvVulkanRenderPass;
                                        const aWidth:TpvUInt32;
                                        const aHeight:TpvUInt32;
                                        const aLayers:TpvUInt32;
                                        const aFrameBufferHandle:TVkFrameBuffer;
                                        const aFrameBufferAttachments:array of TpvVulkanFrameBufferAttachment;
                                        const aDoDestroy:boolean=true;
                                        const aDoDestroyAttachments:boolean=true);
begin

 inherited Create;

 fDevice:=aDevice;

 fFrameBufferHandle:=aFrameBufferHandle;

 fFrameBufferAttachments:=nil;

 fFrameBufferAttachmentImageViews:=nil;

 fCountFrameBufferAttachments:=length(aFrameBufferAttachments);

 SetLength(fFrameBufferAttachments,fCountFrameBufferAttachments);

 if fCountFrameBufferAttachments>0 then begin
  Move(aFrameBufferAttachments[0],fFrameBufferAttachments[0],fCountFrameBufferAttachments*SizeOf(TpvVulkanFrameBufferAttachment));
 end;

 fRenderPass:=aRenderPass;

 fWidth:=aWidth;

 fHeight:=aHeight;

 fLayers:=aLayers;

 fDoDestroy:=aDoDestroy;

 fDoDestroyAttachments:=aDoDestroyAttachments;

end;

destructor TpvVulkanFrameBuffer.Destroy;
var Index:TpvInt32;
begin

 if fFrameBufferHandle<>VK_NULL_HANDLE then begin
  if fDoDestroy then begin
   fDevice.fDeviceVulkan.DestroyFramebuffer(fDevice.fDeviceHandle,fFrameBufferHandle,fDevice.fAllocationCallbacks);
  end;
  fFrameBufferHandle:=VK_NULL_HANDLE;
 end;

 for Index:=0 to fCountFrameBufferAttachments-1 do begin
  if fDoDestroyAttachments then begin
   FreeAndNil(fFrameBufferAttachments[Index]);
  end else begin
   fFrameBufferAttachments[Index]:=nil;
  end;
 end;

 SetLength(fFrameBufferAttachments,0);

 SetLength(fFrameBufferAttachmentImageViews,0);

 inherited Destroy;
end;

function TpvVulkanFrameBuffer.GetFrameBufferAttachment(const aIndex:TpvInt32):TpvVulkanFrameBufferAttachment;
begin
 result:=fFrameBufferAttachments[aIndex];
end;

function TpvVulkanFrameBuffer.AddAttachment(const aFrameBufferAttachment:TpvVulkanFrameBufferAttachment):TpvInt32;
begin
 result:=fCountFrameBufferAttachments;
 inc(fCountFrameBufferAttachments);
 if fCountFrameBufferAttachments>length(fFrameBufferAttachments) then begin
  SetLength(fFrameBufferAttachments,fCountFrameBufferAttachments*2);
 end;
 fFrameBufferAttachments[result]:=aFrameBufferAttachment;
end;

procedure TpvVulkanFrameBuffer.Initialize;
var Index:TpvInt32;
    FrameBufferCreateInfo:TVkFramebufferCreateInfo;
begin
 if fFrameBufferHandle=VK_NULL_HANDLE then begin

  SetLength(fFrameBufferAttachments,fCountFrameBufferAttachments);

  SetLength(fFrameBufferAttachmentImageViews,fCountFrameBufferAttachments);

  for Index:=0 to fCountFrameBufferAttachments-1 do begin
   fFrameBufferAttachmentImageViews[Index]:=fFrameBufferAttachments[Index].fImageView.fImageViewHandle;
  end;

  FillChar(FrameBufferCreateInfo,SizeOf(TVkFramebufferCreateInfo),#0);
  FrameBufferCreateInfo.sType:=VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
  FrameBufferCreateInfo.pNext:=nil;
  FrameBufferCreateInfo.flags:=0;
  FrameBufferCreateInfo.renderPass:=fRenderPass.fRenderPassHandle;
  FrameBufferCreateInfo.attachmentCount:=fCountFrameBufferAttachments;
  FrameBufferCreateInfo.pAttachments:=@fFrameBufferAttachmentImageViews[0];
  FrameBufferCreateInfo.width:=fWidth;
  FrameBufferCreateInfo.height:=fHeight;
  FrameBufferCreateInfo.layers:=fLayers;

  HandleResultCode(fDevice.fDeviceVulkan.CreateFramebuffer(fDevice.fDeviceHandle,@FrameBufferCreateInfo,fDevice.fAllocationCallbacks,@fFrameBufferHandle));

 end;
end;

constructor TpvVulkanSwapChain.Create(const aDevice:TpvVulkanDevice;
                                      const aSurface:TpvVulkanSurface;
                                      const aOldSwapChain:TpvVulkanSwapChain=nil;
                                      const aDesiredImageWidth:TpvUInt32=0;
                                      const aDesiredImageHeight:TpvUInt32=0;
                                      const aDesiredImageCount:TpvUInt32=2;
                                      const aImageArrayLayers:TpvUInt32=1;
                                      const aImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                                      const aImageColorSpace:TVkColorSpaceKHR=VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
                                      const aImageUsage:TVkImageUsageFlags=TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
                                      const aImageSharingMode:TVkSharingMode=VK_SHARING_MODE_EXCLUSIVE;
                                      const aQueueFamilyIndices:TVkUInt32List=nil;
                                      const aCompositeAlpha:TVkCompositeAlphaFlagBitsKHR=VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
                                      const aPresentMode:TVkPresentModeKHR=VK_PRESENT_MODE_MAILBOX_KHR;
                                      const aClipped:boolean=true;
                                      const aDesiredTransform:TVkSurfaceTransformFlagsKHR=TVkSurfaceTransformFlagsKHR($ffffffff);
                                      const aSRGB:boolean=false);
type TPresentModes=VK_PRESENT_MODE_IMMEDIATE_KHR..VK_PRESENT_MODE_FIFO_RELAXED_KHR;
const PresentModeTryOrder:array[TPresentModes,0..3] of TVkPresentModeKHR=
       ((VK_PRESENT_MODE_IMMEDIATE_KHR,VK_PRESENT_MODE_MAILBOX_KHR,VK_PRESENT_MODE_FIFO_RELAXED_KHR,VK_PRESENT_MODE_FIFO_KHR),
        (VK_PRESENT_MODE_MAILBOX_KHR,VK_PRESENT_MODE_IMMEDIATE_KHR,VK_PRESENT_MODE_FIFO_RELAXED_KHR,VK_PRESENT_MODE_FIFO_KHR),
        (VK_PRESENT_MODE_FIFO_KHR,VK_PRESENT_MODE_FIFO_RELAXED_KHR,VK_PRESENT_MODE_MAILBOX_KHR,VK_PRESENT_MODE_IMMEDIATE_KHR),
        (VK_PRESENT_MODE_FIFO_RELAXED_KHR,VK_PRESENT_MODE_FIFO_KHR,VK_PRESENT_MODE_MAILBOX_KHR,VK_PRESENT_MODE_IMMEDIATE_KHR));
var Index,TryIterationIndex:TpvInt32;
    SurfaceCapabilities:TVkSurfaceCapabilitiesKHR;
    SurfacePresentModes:TVkPresentModeKHRArray;
    SurfaceFormat:TVkSurfaceFormatKHR;
    SwapChainImages:array of TVkImage;
    FormatProperties:TVkFormatProperties;
    SwapChainCreateInfo:TVkSwapchainCreateInfoKHR;
    Found:boolean;
begin
 inherited Create;

 fDevice:=aDevice;

 fSurface:=aSurface;

 fSwapChainHandle:=VK_NULL_HANDLE;

 fQueueFamilyIndices:=nil;

 fImages:=nil;

 fPresentMode:=aPresentMode;

 fPreviousImageIndex:=0;

 fCurrentImageIndex:=0;

 fCountImages:=0;

 fWidth:=0;

 fHeight:=0;

 try

  if (fDevice.fPresentQueueFamilyIndex<0) or not
     fDevice.fPhysicalDevice.GetSurfaceSupport(fDevice.fPresentQueueFamilyIndex,fSurface) then begin
   raise EpvVulkanSurfaceException.Create('Surface not supported by device');
  end;

  if assigned(aQueueFamilyIndices) then begin
   fCountQueueFamilyIndices:=aQueueFamilyIndices.Count;
   SetLength(fQueueFamilyIndices,fCountQueueFamilyIndices);
   for Index:=0 to fCountQueueFamilyIndices-1 do begin
    fQueueFamilyIndices[Index]:=aQueueFamilyIndices.Items[Index];
   end;
  end else begin
   fCountQueueFamilyIndices:=0;
  end;

  SurfaceCapabilities:=fDevice.fPhysicalDevice.GetSurfaceCapabilities(fSurface);

  FillChar(SwapChainCreateInfo,SizeOf(TVkSwapChainCreateInfoKHR),#0);
  SwapChainCreateInfo.sType:=VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;

  SwapChainCreateInfo.surface:=fSurface.fSurfaceHandle;

  if SurfaceCapabilities.minImageCount>aDesiredImageCount then begin
   SwapChainCreateInfo.minImageCount:=SurfaceCapabilities.minImageCount;
  end else if (SurfaceCapabilities.maxImageCount<>0) and
              (SurfaceCapabilities.maxImageCount<aDesiredImageCount) then begin
   SwapChainCreateInfo.minImageCount:=SurfaceCapabilities.maxImageCount;
  end else begin
   SwapChainCreateInfo.minImageCount:=aDesiredImageCount;
  end;

  if aImageFormat=VK_FORMAT_UNDEFINED then begin
   SurfaceFormat:=fDevice.fPhysicalDevice.GetSurfaceFormat(fSurface,aSRGB);
   SwapChainCreateInfo.imageFormat:=SurfaceFormat.format;
   SwapChainCreateInfo.imageColorSpace:=SurfaceFormat.colorSpace;
  end else begin
   SwapChainCreateInfo.imageFormat:=aImageFormat;
   SwapChainCreateInfo.imageColorSpace:=aImageColorSpace;
  end;

  fImageFormat:=SwapChainCreateInfo.imageFormat;
  fImageColorSpace:=SwapChainCreateInfo.imageColorSpace;
   
  fDevice.fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fDevice.fPhysicalDevice.fPhysicalDeviceHandle,SwapChainCreateInfo.imageFormat,@FormatProperties);
  if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT))=0 then begin
   raise EpvVulkanException.Create('No suitable color image format!');
  end;

  if ((aDesiredImageWidth<>0) and (aDesiredImageHeight<>0)) or
     ((TpvInt32(SurfaceCapabilities.CurrentExtent.Width)<0) or (TpvInt32(SurfaceCapabilities.CurrentExtent.Height)<0)) then begin
   SwapChainCreateInfo.imageExtent.width:=Min(Max(aDesiredImageWidth,SurfaceCapabilities.minImageExtent.width),SurfaceCapabilities.maxImageExtent.width);
   SwapChainCreateInfo.imageExtent.height:=Min(Max(aDesiredImageHeight,SurfaceCapabilities.minImageExtent.height),SurfaceCapabilities.maxImageExtent.height);
  end else begin
   SwapChainCreateInfo.imageExtent:=SurfaceCapabilities.CurrentExtent;
  end;

  fWidth:=SwapChainCreateInfo.imageExtent.width;

  fHeight:=SwapChainCreateInfo.imageExtent.height;

  SwapChainCreateInfo.imageArrayLayers:=aImageArrayLayers;
  SwapChainCreateInfo.imageUsage:=aImageUsage;
  SwapChainCreateInfo.imageSharingMode:=aImageSharingMode;

  if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_BLIT_DST_BIT))<>0 then begin
   SwapChainCreateInfo.imageUsage:=SwapChainCreateInfo.imageUsage or TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT);
  end;

  if fCountQueueFamilyIndices>0 then begin
   SwapChainCreateInfo.pQueueFamilyIndices:=@fQueueFamilyIndices[0];
   SwapChainCreateInfo.queueFamilyIndexCount:=fCountQueueFamilyIndices;
  end;

  if (aDesiredTransform<>TVkSurfaceTransformFlagsKHR($ffffffff)) and
     ((SurfaceCapabilities.SupportedTransforms and aDesiredTransform)<>0) then begin
   SwapChainCreateInfo.preTransform:=TVkSurfaceTransformFlagBitsKHR(aDesiredTransform);
  end else if (SurfaceCapabilities.SupportedTransforms and TVkSurfaceTransformFlagsKHR(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR))<>0 then begin
   SwapChainCreateInfo.preTransform:=TVkSurfaceTransformFlagBitsKHR(VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR);
  end else begin
   SwapChainCreateInfo.preTransform:=TVkSurfaceTransformFlagBitsKHR(SurfaceCapabilities.currentTransform);
  end;

  SwapChainCreateInfo.compositeAlpha:=aCompositeAlpha;

  SurfacePresentModes:=nil;
  try
   SurfacePresentModes:=fDevice.fPhysicalDevice.GetSurfacePresentModes(fSurface);
   case aPresentMode of
    VK_PRESENT_MODE_IMMEDIATE_KHR..VK_PRESENT_MODE_FIFO_RELAXED_KHR:begin
     SwapChainCreateInfo.presentMode:=VK_PRESENT_MODE_FIFO_KHR;
     Found:=false;
     for Index:=0 to length(SurfacePresentModes)-1 do begin
      if SurfacePresentModes[Index]=aPresentMode then begin
       SwapChainCreateInfo.presentMode:=aPresentMode;
       Found:=true;
       break;
      end;
     end;
     if not Found then begin
      for TryIterationIndex:=0 to 3 do begin
       Found:=false;
       for Index:=0 to length(SurfacePresentModes)-1 do begin
        if SurfacePresentModes[Index]=PresentModeTryOrder[aPresentMode,TryIterationIndex] then begin
         SwapChainCreateInfo.presentMode:=PresentModeTryOrder[aPresentMode,TryIterationIndex];
         Found:=true;
         break;
        end;
       end;
       if Found then begin
        break;
       end;
      end;
     end;
    end;
    else begin
     SwapChainCreateInfo.presentMode:=VK_PRESENT_MODE_FIFO_KHR;
     Found:=false;
     for Index:=0 to length(SurfacePresentModes)-1 do begin
      if SurfacePresentModes[Index]=aPresentMode then begin
       SwapChainCreateInfo.presentMode:=aPresentMode;
       Found:=true;
       break;
      end;
     end;
     if not Found then begin
      for Index:=0 to length(SurfacePresentModes)-1 do begin
       if SurfacePresentModes[Index]=VK_PRESENT_MODE_FIFO_KHR then begin
        SwapChainCreateInfo.presentMode:=VK_PRESENT_MODE_FIFO_KHR;
        Found:=true;
        break;
       end;
      end;
      if not Found then begin
       if length(SurfacePresentModes)>0 then begin
        SwapChainCreateInfo.presentMode:=SurfacePresentModes[0];
       end else begin
        raise EpvVulkanException.Create('Vulkan initialization error (no suitable present mode found, buggy graphics driver?)');
       end;
      end;
     end;
    end;
   end;
  finally
   SetLength(SurfacePresentModes,0);
  end;

  if aClipped then begin
   SwapChainCreateInfo.clipped:=VK_TRUE;
  end else begin
   SwapChainCreateInfo.clipped:=VK_FALSE;
  end;

  if assigned(aOldSwapChain) then begin
   SwapChainCreateInfo.oldSwapchain:=aOldSwapChain.fSwapChainHandle;
  end else begin
   SwapChainCreateInfo.oldSwapchain:=VK_NULL_HANDLE;
  end;

  HandleResultCode(fDevice.fDeviceVulkan.CreateSwapChainKHR(fDevice.fDeviceHandle,@SwapChainCreateInfo,fDevice.fAllocationCallbacks,@fSwapChainHandle));

  HandleResultCode(fDevice.fDeviceVulkan.GetSwapchainImagesKHR(fDevice.fDeviceHandle,fSwapChainHandle,@fCountImages,nil));

  SwapChainImages:=nil;
  try
   SetLength(SwapChainImages,fCountImages);

   HandleResultCode(fDevice.fDeviceVulkan.GetSwapchainImagesKHR(fDevice.fDeviceHandle,fSwapChainHandle,@fCountImages,@SwapChainImages[0]));

   SetLength(fImages,fCountImages);
   for Index:=0 to fCountImages-1 do begin
    fImages[Index]:=nil;
   end;

   for Index:=0 to fCountImages-1 do begin
    fImages[Index]:=TpvVulkanImage.Create(fDevice,SwapChainImages[Index],nil,false);
   end;

  finally
   SetLength(SwapChainImages,0);
  end;

  fPreviousImageIndex:=0;

  fCurrentImageIndex:=fCountImages-1;

 except

  for Index:=0 to length(fImages)-1 do begin
   FreeAndNil(fImages[Index]);
  end;

  if fSwapChainHandle<>VK_NULL_HANDLE then begin
   fDevice.fDeviceVulkan.DestroySwapChainKHR(fDevice.fDeviceHandle,fSwapChainHandle,fDevice.fAllocationCallbacks);
   fSwapChainHandle:=VK_NULL_HANDLE;
  end;

  SetLength(fQueueFamilyIndices,0);

  SetLength(fImages,0);
  
  raise;

 end;
end;

destructor TpvVulkanSwapChain.Destroy;
var Index:TpvInt32;
begin

 for Index:=0 to length(fImages)-1 do begin
  FreeAndNil(fImages[Index]);
 end;

 if fSwapChainHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroySwapChainKHR(fDevice.fDeviceHandle,fSwapChainHandle,fDevice.fAllocationCallbacks);
  fSwapChainHandle:=VK_NULL_HANDLE;
 end;

 SetLength(fQueueFamilyIndices,0);

 SetLength(fImages,0);

 inherited Destroy;
end;

function TpvVulkanSwapChain.QueuePresent(const aQueue:TpvVulkanQueue;const aSemaphore:TpvVulkanSemaphore=nil):TVkResult;
var PresentInfo:TVkPresentInfoKHR;
begin
 FillChar(PresentInfo,SizeOf(TVkPresentInfoKHR),#0);
 PresentInfo.sType:=VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
 PresentInfo.swapchainCount:=1;
 PresentInfo.pSwapchains:=@fSwapChainHandle;
 PresentInfo.pImageIndices:=@fCurrentImageIndex;
 if assigned(aSemaphore) then begin
  PresentInfo.waitSemaphoreCount:=1;
  PresentInfo.pWaitSemaphores:=@aSemaphore.fSemaphoreHandle;
 end;
 result:=fDevice.fInstance.fInstanceVulkan.QueuePresentKHR(aQueue.fQueueHandle,@PresentInfo);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

function TpvVulkanSwapChain.AcquireNextImage(const aSemaphore:TpvVulkanSemaphore=nil;const aFence:TpvVulkanFence=nil;const aTimeOut:TpvUInt64=TpvUInt64(high(TpvUInt64))):TVkResult;
var SemaphoreHandle:TVkFence;
    FenceHandle:TVkFence;
begin
 fPreviousImageIndex:=fCurrentImageIndex;
 if assigned(aSemaphore) then begin
  SemaphoreHandle:=aSemaphore.fSemaphoreHandle;
 end else begin
  SemaphoreHandle:=VK_NULL_HANDLE;
 end;
 if assigned(aFence) then begin
  FenceHandle:=aFence.fFenceHandle;
 end else begin
  FenceHandle:=VK_NULL_HANDLE;
 end;
 result:=fDevice.fDeviceVulkan.AcquireNextImageKHR(fDevice.fDeviceHandle,fSwapChainHandle,aTimeOut,SemaphoreHandle,FenceHandle,@fCurrentImageIndex);
 if result<VK_SUCCESS then begin
  HandleResultCode(result);
 end;
end;

function TpvVulkanSwapChain.GetImage(const aImageIndex:TpvInt32):TpvVulkanImage;
begin
 result:=fImages[aImageIndex];
end;

function TpvVulkanSwapChain.GetPreviousImage:TpvVulkanImage;
begin
 result:=fImages[fPreviousImageIndex];
end;

function TpvVulkanSwapChain.GetCurrentImage:TpvVulkanImage;
begin
 result:=fImages[fCurrentImageIndex];
end;

procedure TpvVulkanSwapChain.GetScreenshot(out aScreenshot:TpvVulkanSwapChainScreenshot;const aSwapChainImage:TpvVulkanImage=nil);
type PBytes=^TBytes;
     TBytes=array[0..$7ffffffe] of TpvUInt8;
var x,y:TpvInt32;
    NeedTwoSteps,CopyOnly,BlitSupported,NeedColorSwizzle:boolean;
    SrcColorFormatProperties,
    DstColorFormatProperties:TVkFormatProperties;
    FirstImage,SecondImage:TpvVulkanImage;
    MemoryRequirements:TVkMemoryRequirements;
    FirstMemoryBlock,SecondMemoryBlock:TpvVulkanDeviceMemoryBlock;
    PresentImageMemoryBarrier,DestImageMemoryBarrier,GeneralImageMemoryBarrier,ImageMemoryBarrier:TVkImageMemoryBarrier;
    SrcStages,DstStages:TVkPipelineStageFlags;
    ImageBlit:TVkImageBlit;
    ImageCopy:TVkImageCopy;
    ImageSubresource:TVkImageSubresource;
    SubresourceLayout:TVkSubresourceLayout;
    ImageData,p,pr,pp:PpvUInt8;
    PNGData:TpvPointer;
    PNGDataSize:TpvUInt32;
    DestColorFormat:TVkFormat;
    SwapChainImageHandle:TVkImage;
    Queue:TpvVulkanQueue;
    CommandPool:TpvVulkanCommandPool;
    CommandBuffer:TpvVulkanCommandBuffer;
    Fence:TpvVulkanFence;
begin

 if assigned(aSwapChainImage) then begin
  SwapChainImageHandle:=aSwapChainImage.fImageHandle;
 end else begin
  SwapChainImageHandle:=GetCurrentImage.fImageHandle;
 end;

 aScreenshot.Width:=fWidth;
 aScreenshot.Height:=fHeight;
 SetLength(aScreenshot.Data,fWidth*fHeight*SizeOf(TpvUInt8)*4);

 fDevice.GraphicsQueue.WaitIdle;

 fDevice.WaitIdle;

 if ImageFormat in [VK_FORMAT_R8G8B8A8_SRGB,VK_FORMAT_B8G8R8A8_SRGB] then begin
  DestColorFormat:=VK_FORMAT_R8G8B8A8_SRGB;
 end else begin
  DestColorFormat:=VK_FORMAT_R8G8B8A8_UNORM;
 end;

 SrcColorFormatProperties:=fDevice.fPhysicalDevice.GetFormatProperties(ImageFormat);

 DstColorFormatProperties:=fDevice.fPhysicalDevice.GetFormatProperties(DestColorFormat);

 BlitSupported:=((SrcColorFormatProperties.optimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_BLIT_SRC_BIT))<>0) and
                ((DstColorFormatProperties.optimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_BLIT_DST_BIT))<>0);

 NeedTwoSteps:=(ImageFormat<>DestColorFormat) and
               (((DstColorFormatProperties.linearTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_BLIT_DST_BIT))=0) and
                ((DstColorFormatProperties.optimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_BLIT_DST_BIT))<>0));

 CopyOnly:=(ImageFormat=DestColorFormat) or
           (((DstColorFormatProperties.linearTilingFeatures or DstColorFormatProperties.optimalTilingFeatures) and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_BLIT_DST_BIT))=0);

 FirstImage:=TpvVulkanImage.Create(fDevice,
                                   0,
                                   VK_IMAGE_TYPE_2D,
                                   DestColorFormat,
                                   fWidth,
                                   fHeight,
                                   1,
                                   1,
                                   1,
                                   VK_SAMPLE_COUNT_1_BIT,
                                   TVkImageTiling(TpvInt32(IfThen(NeedTwoSteps,
                                                                  TpvInt32(VK_IMAGE_TILING_OPTIMAL),
                                                                  TpvInt32(VK_IMAGE_TILING_LINEAR)))),
                                   IfThen(NeedTwoSteps,
                                          TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT) or TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT),
                                          TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT)),
                                   VK_SHARING_MODE_EXCLUSIVE,
                                   [],
                                   VK_IMAGE_LAYOUT_UNDEFINED);
 try

  fDevice.fDeviceVulkan.GetImageMemoryRequirements(fDevice.fDeviceHandle,FirstImage.fImageHandle,@MemoryRequirements);

  if NeedTwoSteps then begin
   FirstMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock([],
                                                                MemoryRequirements.size,
                                                                MemoryRequirements.alignment,
                                                                MemoryRequirements.memoryTypeBits,
                                                                TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                vdmatImageOptimal);
  end else begin
   FirstMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock([vdmbfPersistentMapped],
                                                                MemoryRequirements.size,
                                                                MemoryRequirements.alignment,
                                                                MemoryRequirements.memoryTypeBits,
                                                                TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                0,
                                                                vdmatImageLinear);
  end;

  try

   if not assigned(FirstMemoryBlock) then begin
    raise EpvVulkanMemoryAllocationException.Create('Memory for screenshot couldn''t be allocated!');
   end;

   HandleResultCode(fDevice.fDeviceVulkan.BindImageMemory(fDevice.fDeviceHandle,FirstImage.fImageHandle,FirstMemoryBlock.fMemoryChunk.fMemoryHandle,FirstMemoryBlock.fOffset));

   if NeedTwoSteps then begin
    SecondImage:=TpvVulkanImage.Create(fDevice,
                                       0,
                                       VK_IMAGE_TYPE_2D,
                                       DestColorFormat,
                                       fWidth,
                                       fHeight,
                                       1,
                                       1,
                                       1,
                                       VK_SAMPLE_COUNT_1_BIT,
                                       VK_IMAGE_TILING_LINEAR,
                                       TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT),
                                       VK_SHARING_MODE_EXCLUSIVE,
                                       [],
                                       VK_IMAGE_LAYOUT_UNDEFINED);
   end else begin
    SecondImage:=nil;
   end;

   try

    if assigned(SecondImage) then begin

     fDevice.fDeviceVulkan.GetImageMemoryRequirements(fDevice.fDeviceHandle,SecondImage.fImageHandle,@MemoryRequirements);

     SecondMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock([vdmbfPersistentMapped],
                                                                   MemoryRequirements.size,
                                                                   MemoryRequirements.alignment,
                                                                   MemoryRequirements.memoryTypeBits,
                                                                   TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) or TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
                                                                   0,
                                                                   0,
                                                                   0,
                                                                   0,
                                                                   0,
                                                                   vdmatImageLinear);

    end else begin

     SecondMemoryBlock:=nil;

    end;

    try

     if assigned(SecondImage) then begin

      if not assigned(SecondMemoryBlock) then begin
       raise EpvVulkanMemoryAllocationException.Create('Memory for screenshot couldn''t be allocated!');
      end;

      HandleResultCode(fDevice.fDeviceVulkan.BindImageMemory(fDevice.fDeviceHandle,SecondImage.fImageHandle,SecondMemoryBlock.fMemoryChunk.fMemoryHandle,SecondMemoryBlock.fOffset));

     end;

     FillChar(PresentImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
     PresentImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
     PresentImageMemoryBarrier.pNext:=nil;
     PresentImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
     PresentImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
     PresentImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
     PresentImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
     PresentImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     PresentImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     PresentImageMemoryBarrier.image:=SwapChainImageHandle;
     PresentImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
     PresentImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
     PresentImageMemoryBarrier.subresourceRange.levelCount:=1;
     PresentImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
     PresentImageMemoryBarrier.subresourceRange.layerCount:=1;

     FillChar(DestImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
     DestImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
     DestImageMemoryBarrier.pNext:=nil;
     DestImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(0);
     DestImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
     DestImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_UNDEFINED;
     DestImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
     DestImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     DestImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     DestImageMemoryBarrier.image:=FirstImage.fImageHandle;
     DestImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
     DestImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
     DestImageMemoryBarrier.subresourceRange.levelCount:=1;
     DestImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
     DestImageMemoryBarrier.subresourceRange.layerCount:=1;

     FillChar(GeneralImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
     GeneralImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
     GeneralImageMemoryBarrier.pNext:=nil;
     GeneralImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
     GeneralImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
     GeneralImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
     GeneralImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_GENERAL;
     GeneralImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     GeneralImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     GeneralImageMemoryBarrier.image:=FirstImage.fImageHandle;
     GeneralImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
     GeneralImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
     GeneralImageMemoryBarrier.subresourceRange.levelCount:=1;
     GeneralImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
     GeneralImageMemoryBarrier.subresourceRange.layerCount:=1;

     SrcStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT);
     DstStages:=TVkPipelineStageFlags(VK_PIPELINE_STAGE_TRANSFER_BIT);

     Queue:=fDevice.fGraphicsQueue;

     CommandPool:=TpvVulkanCommandPool.Create(fDevice,
                                            fDevice.GraphicsQueueFamilyIndex,
                                            TVkCommandPoolCreateFlags(VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT));
     try

      CommandBuffer:=TpvVulkanCommandBuffer.Create(CommandPool,VK_COMMAND_BUFFER_LEVEL_PRIMARY);
      try

       Fence:=TpvVulkanFence.Create(fDevice);
       try

        CommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
        CommandBuffer.BeginRecording;

        CommandBuffer.CmdPipelineBarrier(SrcStages,
                                         DstStages,
                                         0,
                                         0,nil,
                                         0,nil,
                                         1,@PresentImageMemoryBarrier);

        CommandBuffer.CmdPipelineBarrier(SrcStages,
                                         DstStages,
                                         0,
                                         0,nil,
                                         0,nil,
                                         1,@DestImageMemoryBarrier);

        FillChar(ImageCopy,SizeOf(TVkImageCopy),#0);
        ImageCopy.srcSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
        ImageCopy.srcSubresource.mipLevel:=0;
        ImageCopy.srcSubresource.baseArrayLayer:=0;
        ImageCopy.srcSubresource.layerCount:=1;
        ImageCopy.dstSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
        ImageCopy.dstSubresource.mipLevel:=0;
        ImageCopy.dstSubresource.baseArrayLayer:=0;
        ImageCopy.dstSubresource.layerCount:=1;
        ImageCopy.extent.width:=fWidth;
        ImageCopy.extent.height:=fHeight;
        ImageCopy.extent.depth:=1;

        if CopyOnly then begin

         CommandBuffer.CmdCopyImage(SwapChainImageHandle,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                                    FirstImage.fImageHandle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                    1,@ImageCopy);

        end else begin

         FillChar(ImageBlit,SizeOf(TVkImageBlit),#0);
         ImageBlit.srcSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
         ImageBlit.srcSubresource.mipLevel:=0;
         ImageBlit.srcSubresource.baseArrayLayer:=0;
         ImageBlit.srcSubresource.layerCount:=1;
         ImageBlit.srcOffsets[0].x:=0;
         ImageBlit.srcOffsets[0].y:=0;
         ImageBlit.srcOffsets[0].z:=0;
         ImageBlit.srcOffsets[1].x:=fWidth;
         ImageBlit.srcOffsets[1].y:=fHeight;
         ImageBlit.srcOffsets[1].z:=1;
         ImageBlit.dstSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
         ImageBlit.dstSubresource.mipLevel:=0;
         ImageBlit.dstSubresource.baseArrayLayer:=0;
         ImageBlit.dstSubresource.layerCount:=1;
         ImageBlit.dstOffsets[0].x:=0;
         ImageBlit.dstOffsets[0].y:=0;
         ImageBlit.dstOffsets[0].z:=0;
         ImageBlit.dstOffsets[1].x:=fWidth;
         ImageBlit.dstOffsets[1].y:=fHeight;
         ImageBlit.dstOffsets[1].z:=1;
         CommandBuffer.CmdBlitImage(SwapChainImageHandle,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                                    FirstImage.fImageHandle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                    1,@ImageBlit,
                                    VK_FILTER_NEAREST);

         if NeedTwoSteps then begin

          DestImageMemoryBarrier.image:=SecondImage.fImageHandle;
          CommandBuffer.CmdPipelineBarrier(SrcStages,
                                           DstStages,
                                           0,
                                           0,nil,
                                           0,nil,
                                           1,@DestImageMemoryBarrier);

          DestImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
          DestImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
          DestImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
          DestImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
          DestImageMemoryBarrier.image:=FirstImage.fImageHandle;
          CommandBuffer.CmdPipelineBarrier(SrcStages,
                                           DstStages,
                                           0,
                                           0,nil,
                                           0,nil,
                                           1,@DestImageMemoryBarrier);

          CommandBuffer.CmdCopyImage(FirstImage.fImageHandle,VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                                     SecondImage.fImageHandle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                     1,@ImageCopy);
          GeneralImageMemoryBarrier.image:=SecondImage.fImageHandle;

         end;

        end;

        CommandBuffer.CmdPipelineBarrier(SrcStages,
                                         DstStages,
                                         0,
                                         0,nil,
                                         0,nil,
                                         1,@GeneralImageMemoryBarrier);

        PresentImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
        PresentImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(0);
        PresentImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        PresentImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

        CommandBuffer.CmdPipelineBarrier(SrcStages,
                                         DstStages,
                                         0,
                                         0,nil,
                                         0,nil,
                                         1,@PresentImageMemoryBarrier);


        CommandBuffer.EndRecording;

        CommandBuffer.Execute(Queue,0,nil,nil,Fence,true);

        Queue.WaitIdle;

        fDevice.WaitIdle;

       finally
        Fence.Free;
       end;

      finally
       CommandBuffer.Free;
      end;

     finally
      CommandPool.Free;
     end;

     FillChar(ImageSubresource,SizeOf(TVkImageSubresource),#0);
     ImageSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
     ImageSubresource.mipLevel:=0;
     ImageSubresource.arrayLayer:=0;

     SubresourceLayout.offset:=0;

     if NeedTwoSteps then begin
      fDevice.fDeviceVulkan.GetImageSubresourceLayout(fDevice.fDeviceHandle,SecondImage.fImageHandle,@ImageSubresource,@SubresourceLayout);
      p:=SecondMemoryBlock.MapMemory(0,SecondMemoryBlock.fSize);
     end else begin
      fDevice.fDeviceVulkan.GetImageSubresourceLayout(fDevice.fDeviceHandle,FirstImage.fImageHandle,@ImageSubresource,@SubresourceLayout);
      p:=FirstMemoryBlock.MapMemory(0,FirstMemoryBlock.fSize);
     end;
     if assigned(p) then begin
      try

       inc(p,SubresourceLayout.offset);

       NeedColorSwizzle:=(not BlitSupported) and (fImageFormat in [VK_FORMAT_B8G8R8A8_SRGB,VK_FORMAT_B8G8R8A8_UNORM,VK_FORMAT_B8G8R8A8_SNORM]);

       try
        pp:=@aScreenshot.Data[0];
        for y:=0 to fHeight-1 do begin
         pr:=p;
         for x:=0 to fWidth-1 do begin
          if NeedColorSwizzle then begin
           PBytes(TpvPointer(pp))^[0]:=PBytes(TpvPointer(pr))^[2];
           PBytes(TpvPointer(pp))^[1]:=PBytes(TpvPointer(pr))^[1];
           PBytes(TpvPointer(pp))^[2]:=PBytes(TpvPointer(pr))^[0];
           PBytes(TpvPointer(pp))^[3]:=$ff;//PBytes(TpvPointer(pr))^[3];
          end else begin
           PBytes(TpvPointer(pp))^[0]:=PBytes(TpvPointer(pr))^[0];
           PBytes(TpvPointer(pp))^[1]:=PBytes(TpvPointer(pr))^[1];
           PBytes(TpvPointer(pp))^[2]:=PBytes(TpvPointer(pr))^[2];
           PBytes(TpvPointer(pp))^[3]:=$ff;//PBytes(TpvPointer(pr))^[3];
          end;
          inc(pp,4);
          inc(pr,4);
         end;
         inc(p,SubresourceLayout.rowPitch);
        end;

       finally
       end;

      finally
       if NeedTwoSteps then begin
        SecondMemoryBlock.UnmapMemory;
       end else begin
        FirstMemoryBlock.UnmapMemory;
       end;
      end;
     end;

    finally
     SecondMemoryBlock.Free;
    end;

   finally
    SecondImage.Free;
   end;

  finally
   FirstMemoryBlock.Free;
  end;

 finally
  FirstImage.Free;
 end;

end;

procedure TpvVulkanSwapChain.SaveScreenshotAsJPEGToStream(const aStream:TStream;const aSwapChainImage:TpvVulkanImage=nil;const aQuality:TpvInt32=95);
var SwapChainScreenshot:TpvVulkanSwapChainScreenshot;
    JPEGData:TpvPointer;
    JPEGDataSize:TpvUInt32;
begin
 Initialize(SwapChainScreenshot);
 try
  SwapChainScreenshot.Data:=nil;
  GetScreenshot(SwapChainScreenshot,aSwapChainImage);
  if length(SwapChainScreenshot.Data)>0 then begin
   SaveJPEGImage(@SwapChainScreenshot.Data[0],SwapChainScreenshot.Width,SwapChainScreenshot.Height,JPEGData,JPEGDataSize,aQuality,false,-1);
   if assigned(JPEGData) then begin
    try
     aStream.Seek(0,soBeginning);
     aStream.WriteBuffer(JPEGData^,JPEGDataSize);
     aStream.Seek(0,soBeginning);
    finally
     FreeMem(JPEGData);
    end;
   end;
  end;
 finally
  Finalize(SwapChainScreenshot);
 end;
end;

procedure TpvVulkanSwapChain.SaveScreenshotAsPNGToStream(const aStream:TStream;const aSwapChainImage:TpvVulkanImage=nil);
var SwapChainScreenshot:TpvVulkanSwapChainScreenshot;
    PNGData:TpvPointer;
    PNGDataSize:TpvUInt32;
begin
 Initialize(SwapChainScreenshot);
 try
  SwapChainScreenshot.Data:=nil;
  GetScreenshot(SwapChainScreenshot,aSwapChainImage);
  if length(SwapChainScreenshot.Data)>0 then begin
   SavePNGImage(@SwapChainScreenshot.Data[0],SwapChainScreenshot.Width,SwapChainScreenshot.Height,PNGData,PNGDataSize,pvppfR8G8B8A8);
   if assigned(PNGData) then begin
    try
     aStream.Seek(0,soBeginning);
     aStream.WriteBuffer(PNGData^,PNGDataSize);
     aStream.Seek(0,soBeginning);
    finally
     FreeMem(PNGData);
    end;
   end;
  end;
 finally
  Finalize(SwapChainScreenshot);
 end;
end;

constructor TpvVulkanSwapChainSimpleDirectRenderTarget.Create(const aDevice:TpvVulkanDevice;
                                                              const aSwapChain:TpvVulkanSwapChain;
                                                              const aPresentQueue:TpvVulkanQueue;
                                                              const aPresentCommandBuffer:TpvVulkanCommandBuffer;
                                                              const aPresentCommandBufferFence:TpvVulkanFence;
                                                              const aGraphicsQueue:TpvVulkanQueue;
                                                              const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                                              const aGraphicsCommandBufferFence:TpvVulkanFence;
                                                              const aDepthImageFormat:TVkFormat=VK_FORMAT_UNDEFINED;
                                                              const aDepthImageFormatWithStencil:boolean=false;
                                                              const aClear:boolean=true);
var Index:TpvInt32;
    FormatProperties:TVkFormatProperties;
    ColorAttachmentImage:TpvVulkanImage;
    ColorAttachmentImageView:TpvVulkanImageView;
begin

 inherited Create;

 fDevice:=aDevice;

 fSwapChain:=aSwapChain;

 fFrameBufferColorAttachments:=nil;

 fFrameBuffers:=nil;

 fDepthFrameBufferAttachment:=nil;

 fRenderPass:=nil;

 try

  if fDepthImageFormat=VK_FORMAT_UNDEFINED then begin
   fDepthImageFormat:=fDevice.fPhysicalDevice.GetBestSupportedDepthFormat(aDepthImageFormatWithStencil);
  end else begin
   fDepthImageFormat:=aDepthImageFormat;
  end;

  fDevice.fInstance.fVulkan.GetPhysicalDeviceFormatProperties(fDevice.fPhysicalDevice.fPhysicalDeviceHandle,fDepthImageFormat,@FormatProperties);
  if (FormatProperties.OptimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_DEPTH_STENCIL_ATTACHMENT_BIT))=0 then begin
   raise EpvVulkanException.Create('No suitable depth image format!');
  end;

  begin

   fRenderPass:=TpvVulkanRenderPass.Create(fDevice);

   if aClear then begin

    fRenderPass.AddSubpassDescription(0,
                                      VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      [],
                                      [fRenderPass.AddAttachmentReference(fRenderPass.AddAttachmentDescription(0,
                                                                                                               fSwapChain.ImageFormat,
                                                                                                               VK_SAMPLE_COUNT_1_BIT,
                                                                                                               VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                               VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                               VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                               VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                               VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, //VK_IMAGE_LAYOUT_UNDEFINED, // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                                                                                               VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL //VK_IMAGE_LAYOUT_PRESENT_SRC_KHR  // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                                                              ),
                                                                          VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                         )],
                                      [],
                                      fRenderPass.AddAttachmentReference(fRenderPass.AddAttachmentDescription(0,
                                                                                                              fDepthImageFormat,
                                                                                                              VK_SAMPLE_COUNT_1_BIT,
                                                                                                              VK_ATTACHMENT_LOAD_OP_CLEAR,
                                                                                                              VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                              VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                              VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                              VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, // VK_IMAGE_LAYOUT_UNDEFINED, // VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                                                                                              VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                                                             ),
                                                                         VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                        ),
                                      []);

   end else begin

    fRenderPass.AddSubpassDescription(0,
                                      VK_PIPELINE_BIND_POINT_GRAPHICS,
                                      [],
                                      [fRenderPass.AddAttachmentReference(fRenderPass.AddAttachmentDescription(0,
                                                                                                               fSwapChain.ImageFormat,
                                                                                                               VK_SAMPLE_COUNT_1_BIT,
                                                                                                               VK_ATTACHMENT_LOAD_OP_LOAD,
                                                                                                               VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                               VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                               VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                               VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL, //VK_IMAGE_LAYOUT_UNDEFINED, // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
                                                                                                               VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL //VK_IMAGE_LAYOUT_PRESENT_SRC_KHR  // VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                                                              ),
                                                                          VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL
                                                                         )],
                                      [],
                                      fRenderPass.AddAttachmentReference(fRenderPass.AddAttachmentDescription(0,
                                                                                                              fDepthImageFormat,
                                                                                                              VK_SAMPLE_COUNT_1_BIT,
                                                                                                              VK_ATTACHMENT_LOAD_OP_LOAD,
                                                                                                              VK_ATTACHMENT_STORE_OP_STORE,
                                                                                                              VK_ATTACHMENT_LOAD_OP_DONT_CARE,
                                                                                                              VK_ATTACHMENT_STORE_OP_DONT_CARE,
                                                                                                              VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL, // VK_IMAGE_LAYOUT_UNDEFINED, // VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL,
                                                                                                              VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                                                             ),
                                                                         VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL
                                                                        ),
                                      []);

   end;

   fRenderPass.AddSubpassDependency(VK_SUBPASS_EXTERNAL,
                                    0,
                                    TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                    TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                                    TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT),
                                    TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
                                    TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT));

   fRenderPass.AddSubpassDependency(0,
                                    VK_SUBPASS_EXTERNAL,
                                    TVkPipelineStageFlags(VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT),
                                    TVkPipelineStageFlags(VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT),
                                    TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_READ_BIT) or TVkAccessFlags(VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT),
                                    TVkAccessFlags(VK_ACCESS_MEMORY_READ_BIT),
                                    TVkDependencyFlags(VK_DEPENDENCY_BY_REGION_BIT));

   fRenderPass.Initialize;

   if aClear then begin
    fRenderPass.ClearValues[0].color.float32[0]:=0.0;
    fRenderPass.ClearValues[0].color.float32[1]:=0.0;
    fRenderPass.ClearValues[0].color.float32[2]:=0.0;
    fRenderPass.ClearValues[0].color.float32[3]:=1.0;
   end;

  end;

  SetLength(fFrameBufferColorAttachments,fSwapChain.CountImages);

  for Index:=0 to fSwapChain.CountImages-1 do begin
   fFrameBufferColorAttachments[Index]:=nil;
  end;

  for Index:=0 to fSwapChain.CountImages-1 do begin

   ColorAttachmentImage:=nil;

   ColorAttachmentImageView:=nil;

   try
    ColorAttachmentImage:=TpvVulkanImage.Create(fDevice,fSwapChain.Images[Index].fImageHandle,nil,false);

    ColorAttachmentImage.SetLayout(TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                   VK_IMAGE_LAYOUT_UNDEFINED,
                                   VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
                                   nil,
                                   aPresentCommandBuffer,
                                   aPresentQueue,
                                   aPresentCommandBufferFence,
                                   true);

    ColorAttachmentImageView:=TpvVulkanImageView.Create(Device,
                                                        ColorAttachmentImage,
                                                        VK_IMAGE_VIEW_TYPE_2D,
                                                        fSwapChain.ImageFormat,
                                                        VK_COMPONENT_SWIZZLE_IDENTITY,
                                                        VK_COMPONENT_SWIZZLE_IDENTITY,
                                                        VK_COMPONENT_SWIZZLE_IDENTITY,
                                                        VK_COMPONENT_SWIZZLE_IDENTITY,
                                                        TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                                        0,
                                                        1,
                                                        0,
                                                        1);

    ColorAttachmentImage.fImageView:=ColorAttachmentImageView;
    ColorAttachmentImageView.fImage:=ColorAttachmentImage;

    fFrameBufferColorAttachments[Index]:=TpvVulkanFrameBufferAttachment.Create(fDevice,
                                                                               ColorAttachmentImage,
                                                                               ColorAttachmentImageView,
                                                                               fSwapChain.Width,
                                                                               fSwapChain.Height,
                                                                               fSwapChain.ImageFormat,
                                                                               true);

   except
    FreeAndNil(fFrameBufferColorAttachments[Index]);
    FreeAndNil(ColorAttachmentImageView);
    FreeAndNil(ColorAttachmentImage);
    raise;
   end;

  end;

  fDepthFrameBufferAttachment:=TpvVulkanFrameBufferAttachment.Create(fDevice,
                                                                     aGraphicsQueue,
                                                                     aGraphicsCommandBuffer,
                                                                     aGraphicsCommandBufferFence,
                                                                     fSwapChain.Width,
                                                                     fSwapChain.Height,
                                                                     fDepthImageFormat,
                                                                     TVkBufferUsageFlags(VK_IMAGE_USAGE_DEPTH_STENCIL_ATTACHMENT_BIT));

  SetLength(fFrameBuffers,fSwapChain.CountImages);
  for Index:=0 to fSwapChain.CountImages-1 do begin
   fFrameBuffers[Index]:=nil;
  end;
  for Index:=0 to fSwapChain.CountImages-1 do begin
   fFrameBuffers[Index]:=TpvVulkanFrameBuffer.Create(fDevice,
                                                     fRenderPass,
                                                     fSwapChain.Width,
                                                     fSwapChain.Height,
                                                     1,
                                                     [fFrameBufferColorAttachments[Index],fDepthFrameBufferAttachment],
                                                     false);
  end;

 except

  for Index:=0 to length(fFramebuffers)-1 do begin
   FreeAndNil(fFrameBuffers[Index]);
  end;

  FreeAndNil(fRenderPass);

  FreeAndNil(fDepthFrameBufferAttachment);

  for Index:=0 to length(fFrameBufferColorAttachments)-1 do begin
   FreeAndNil(fFrameBufferColorAttachments[Index]);
  end;

  SetLength(fFrameBufferColorAttachments,0);

  SetLength(fFrameBuffers,0);

  raise;

 end;

end;

destructor TpvVulkanSwapChainSimpleDirectRenderTarget.Destroy;
var Index:TpvInt32;
begin

 for Index:=0 to length(fFramebuffers)-1 do begin
   FreeAndNil(fFrameBuffers[Index]);
 end;

 FreeAndNil(fRenderPass);

 FreeAndNil(fDepthFrameBufferAttachment);

 for Index:=0 to length(fFrameBufferColorAttachments)-1 do begin
  FreeAndNil(fFrameBufferColorAttachments[Index]);
 end;

 SetLength(fFrameBufferColorAttachments,0);
 SetLength(fFrameBuffers,0);

 inherited Destroy;
end;

function TpvVulkanSwapChainSimpleDirectRenderTarget.GetRenderPass:TpvVulkanRenderPass;
begin
 result:=fRenderPass;
end;

function TpvVulkanSwapChainSimpleDirectRenderTarget.GetFrameBuffer:TpvVulkanFrameBuffer;
begin
 result:=fFrameBuffers[fSwapChain.CurrentImageIndex];
end;

function TpvVulkanSwapChainSimpleDirectRenderTarget.GetFrameBufferAtIndex(const aIndex:TpvInt32):TpvVulkanFrameBuffer;
begin
 result:=fFrameBuffers[aIndex];
end;

constructor TpvVulkanShaderModule.Create(const aDevice:TpvVulkanDevice;const aData;const aDataSize:TVkSize);
begin

 inherited Create;

 fDevice:=aDevice;

 fShaderModuleHandle:=VK_NULL_HANDLE;

 fData:=nil;

 fDataAligned:=nil;

 fDataSize:=aDataSize;
 if (fDataSize and 3)<>0 then begin
  inc(fDataSize,4-(fDataSize and 3));
 end;

 GetMem(fData,fDataSize+4);
 fDataAligned:=fData;
 if (TpvPtrUInt(fDataAligned) and 3)<>0 then begin
  inc(TpvPtrUInt(fDataAligned),4-(TpvPtrUInt(fDataAligned) and 3));
 end;

 Load;

end;

constructor TpvVulkanShaderModule.Create(const aDevice:TpvVulkanDevice;const aStream:TStream);
begin

 inherited Create;

 fDevice:=aDevice;

 fShaderModuleHandle:=VK_NULL_HANDLE;

 fData:=nil;

 fDataAligned:=nil;

 fDataSize:=aStream.Size;
 if (fDataSize and 3)<>0 then begin
  inc(fDataSize,4-(fDataSize and 3));
 end;

 GetMem(fData,fDataSize+4);
 fDataAligned:=fData;
 if (TpvPtrUInt(fDataAligned) and 3)<>0 then begin
  inc(TpvPtrUInt(fDataAligned),4-(TpvPtrUInt(fDataAligned) and 3));
 end;

 if aStream.Seek(0,soBeginning)<>0 then begin
  raise EInOutError.Create('Stream seek error');
 end;

 if aStream.Read(fData^,aStream.Size)<>aStream.Size then begin
  raise EInOutError.Create('Stream read error');
 end;

 Load;

end;

constructor TpvVulkanShaderModule.Create(const aDevice:TpvVulkanDevice;const aFileName:string);
var FileStream:TFileStream;
begin
 FileStream:=TFileStream.Create(aFileName,fmOpenRead or fmShareDenyWrite);
 try
  Create(aDevice,FileStream);
 finally
  FileStream.Free;
 end;
end;

destructor TpvVulkanShaderModule.Destroy;
begin
 if fShaderModuleHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyShaderModule(fDevice.fDeviceHandle,fShaderModuleHandle,fDevice.fAllocationCallbacks);
  fShaderModuleHandle:=VK_NULL_HANDLE;
 end;
 if assigned(fData) then begin
  FreeMem(fData);
  fData:=nil;
 end;
 inherited Destroy;
end;

procedure TpvVulkanShaderModule.Load;
var ShaderModuleCreateInfo:TVkShaderModuleCreateInfo;
begin
 if fShaderModuleHandle=VK_NULL_HANDLE then begin
  FillChar(ShaderModuleCreateInfo,SizeOf(TVkShaderModuleCreateInfo),#0);
  ShaderModuleCreateInfo.sType:=VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
  ShaderModuleCreateInfo.codeSize:=fDataSize;
  ShaderModuleCreateInfo.pCode:=fData;
  HandleResultCode(fDevice.fDeviceVulkan.CreateShaderModule(fDevice.fDeviceHandle,@ShaderModuleCreateInfo,fDevice.fAllocationCallbacks,@fShaderModuleHandle));
 end;
end;

function TpvVulkanShaderModule.GetVariables:TpvVulkanShaderModuleVariables;
// https://www.khronos.org/registry/spir-v/specs/1.1/SPIRV.html
type PUInt32Array=^TUInt32Array;
     TUInt32Array=array[0..65535] of TpvUInt32;
var Position,Size:TpvInt32;
    Opcode,Index,NameIndex,Count,CountIDs,CountNames:TpvUInt32;
    Opcodes:PUInt32Array;
    Endian:boolean;
    Variable:PpvVulkanShaderModuleVariable;
    Bindings,Locations,DescriptorSets:array of TpvUInt32;
    DebugNames:array of TVkCharString;
 function SwapEndian(const Value:TpvUInt32):TpvUInt32;
 begin
  if Endian then begin
   result:=(((Value shr 0) and $ff) shl 24) or
           (((Value shr 8) and $ff) shl 16) or
           (((Value shr 16) and $ff) shl 8) or
           (((Value shr 24) and $ff) shl 0);
  end else begin
   result:=Value;
  end;
 end;
begin
 result:=nil;
 Bindings:=nil;
 Locations:=nil;
 DescriptorSets:=nil;
 DebugNames:=nil;
 Count:=0;
 try
  Opcodes:=fData;
  if assigned(Opcodes) and (fDataSize>=(6*SizeOf(TpvUInt32))) and ((Opcodes^[0]=$07230203) or (Opcodes^[0]=$03022307)) then begin

   Endian:=Opcodes[0]=$03022307;

   Opcodes:=TpvPointer(@Opcodes[5]);

   Size:=(fDataSize shr 2)-5;

   CountIDs:=0;
   CountNames:=0;

   Position:=0;
   while Position<Size do begin
    Opcode:=SwapEndian(Opcodes^[Position]);
    case Opcode and $ffff of
     $0005{OpName}:begin
      CountNames:=Max(CountNames,SwapEndian(Opcodes^[Position+1])+1);
     end;
     $003b{OpVariable}:begin
      inc(Count);
     end;
     $0047{OpOpDecorate}:begin
      CountIDs:=Max(CountIDs,SwapEndian(Opcodes^[Position+1])+1);
     end;
    end;
    inc(Position,Opcode shr 16);
   end;

   SetLength(result,Count);

   try

    SetLength(Bindings,CountIDs);
    SetLength(Locations,CountIDs);
    SetLength(DescriptorSets,CountIDs);
    SetLength(DebugNames,CountNames);

    Position:=0;
    while Position<Size do begin
     Opcode:=SwapEndian(Opcodes^[Position]);
     case Opcode and $ffff of
      $0005{OpName}:begin
       Index:=SwapEndian(Opcodes^[Position+1]);
       if Index<CountNames then begin
        DebugNames[Index]:=PVkChar(TpvPointer(@Opcodes^[Position+2]));
       end;
      end;
      $0047{OpDecorate}:begin
       Index:=SwapEndian(Opcodes^[Position+1]);
       if Index<CountIDs then begin
        case Opcodes^[Position+2] of
         $0000001e{Location}:begin
          Locations[Index]:=SwapEndian(Opcodes^[Position+3]);
         end;
         $00000021{Binding}:begin
          Bindings[Index]:=SwapEndian(Opcodes^[Position+3]);
         end;
         $00000022{DescriptorSet}:begin
          DescriptorSets[Index]:=SwapEndian(Opcodes^[Position+3]);
         end;
        end;
       end;
      end;
     end;
     inc(Position,Opcode shr 16);
    end;

    Count:=0;
    Position:=0;
    while Position<Size do begin
     Opcode:=SwapEndian(Opcodes^[Position]);
     case Opcode and $ffff of
      $003b{OpVariable}:begin
       Variable:=@result[Count];
       inc(Count);
       Index:=SwapEndian(Opcodes^[Position+1]);
       if Index<CountIDs then begin
        Variable^.fLocation:=Locations[Index];
        Variable^.fBinding:=Bindings[Index];
        Variable^.fDescriptorSet:=DescriptorSets[Index];
       end else begin
        Variable^.fLocation:=0;
        Variable^.fBinding:=0;
        Variable^.fDescriptorSet:=0;
       end;
       NameIndex:=SwapEndian(Opcodes^[Position+2]);
       if NameIndex<CountNames then begin
        Variable^.fDebugName:=DebugNames[NameIndex];
       end else begin
        Variable^.fDebugName:='';
       end;
       Variable^.fName:=NameIndex;
       Variable^.fInstruction:=Position;
       Variable^.fStorageClass:=TpvVulkanShaderModuleVariableStorageClass(SwapEndian(Opcodes^[Position+3]));
      end;
     end;
     inc(Position,Opcode shr 16);
    end;

   finally
    Bindings:=nil;
    Locations:=nil;
    DescriptorSets:=nil;
    DebugNames:=nil;
   end;

  end;
 finally
  SetLength(result,Count);
 end;
end;

constructor TpvVulkanDescriptorPool.Create(const aDevice:TpvVulkanDevice;
                                           const aFlags:TVkDescriptorPoolCreateFlags;
                                           const aMaxSets:TpvUInt32);
begin
 inherited Create;

 fDevice:=aDevice;

 fDescriptorPoolHandle:=VK_NULL_HANDLE;

 fFlags:=aFlags;
 fMaxSets:=aMaxSets;

 fDescriptorPoolSizes:=nil;
 fCountDescriptorPoolSizes:=0;

end;

destructor TpvVulkanDescriptorPool.Destroy;
begin
 if fDescriptorPoolHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyDescriptorPool(fDevice.fDeviceHandle,fDescriptorPoolHandle,fDevice.fAllocationCallbacks);
  fDescriptorPoolHandle:=VK_NULL_HANDLE;
 end;
 SetLength(fDescriptorPoolSizes,0);
 inherited Destroy;
end;

function TpvVulkanDescriptorPool.AddDescriptorPoolSize(const aType:TVkDescriptorType;const aDescriptorCount:TpvUInt32):TpvInt32;
var DescriptorPoolSize:PVkDescriptorPoolSize;
begin
 result:=fCountDescriptorPoolSizes;
 inc(fCountDescriptorPoolSizes);
 if fCountDescriptorPoolSizes>length(fDescriptorPoolSizes) then begin
  SetLength(fDescriptorPoolSizes,fCountDescriptorPoolSizes*2);
 end;
 DescriptorPoolSize:=@fDescriptorPoolSizes[result];
 DescriptorPoolSize.type_:=aType;
 DescriptorPoolSize.descriptorCount:=aDescriptorCount;
end;

procedure TpvVulkanDescriptorPool.Initialize;
var DescriptorPoolCreateInfo:TVkDescriptorPoolCreateInfo;
begin
 if fDescriptorPoolHandle=VK_NULL_HANDLE then begin
  FillChar(DescriptorPoolCreateInfo,SizeOf(TVkDescriptorPoolCreateInfo),#0);
  DescriptorPoolCreateInfo.sType:=VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
  DescriptorPoolCreateInfo.flags:=fFlags;
  DescriptorPoolCreateInfo.maxSets:=fMaxSets;
  if fCountDescriptorPoolSizes>0 then begin
   SetLength(fDescriptorPoolSizes,fCountDescriptorPoolSizes);
   DescriptorPoolCreateInfo.poolSizeCount:=length(fDescriptorPoolSizes);
   DescriptorPoolCreateInfo.pPoolSizes:=@fDescriptorPoolSizes[0];
  end;
  HandleResultCode(fDevice.fDeviceVulkan.CreateDescriptorPool(fDevice.fDeviceHandle,@DescriptorPoolCreateInfo,fDevice.fAllocationCallbacks,@fDescriptorPoolHandle));
 end;
end;

constructor TpvVulkanDescriptorSetLayoutBinding.Create(const aBinding:TpvUInt32;
                                                       const aDescriptorType:TVkDescriptorType;
                                                       const aDescriptorCount:TpvUInt32;
                                                       const aStageFlags:TVkShaderStageFlags);
begin
 inherited Create;

 FillChar(fDescriptorSetLayoutBinding,SizeOf(TVkDescriptorSetLayoutBinding),#0);
 fDescriptorSetLayoutBinding.binding:=aBinding;
 fDescriptorSetLayoutBinding.descriptorType:=aDescriptorType;
 fDescriptorSetLayoutBinding.descriptorCount:=aDescriptorCount;
 fDescriptorSetLayoutBinding.stageFlags:=aStageFlags;

 fImmutableSamplers:=nil;
 fCountImmutableSamplers:=0;

end;

destructor TpvVulkanDescriptorSetLayoutBinding.Destroy;
begin
 SetLength(fImmutableSamplers,0);
 inherited Destroy;
end;

function TpvVulkanDescriptorSetLayoutBinding.GetBinding:TpvUInt32;
begin
 result:=fDescriptorSetLayoutBinding.binding;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.SetBinding(const aBinding:TpvUInt32);
begin
 fDescriptorSetLayoutBinding.binding:=aBinding;
end;

function TpvVulkanDescriptorSetLayoutBinding.GetDescriptorType:TVkDescriptorType;
begin
 result:=fDescriptorSetLayoutBinding.descriptorType;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.SetDescriptorType(const aDescriptorType:TVkDescriptorType);
begin
 fDescriptorSetLayoutBinding.descriptorType:=aDescriptorType;
end;

function TpvVulkanDescriptorSetLayoutBinding.GetDescriptorCount:TpvUInt32;
begin
 result:=fDescriptorSetLayoutBinding.DescriptorCount;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.SetDescriptorCount(const aDescriptorCount:TpvUInt32);
begin
 fDescriptorSetLayoutBinding.descriptorCount:=aDescriptorCount;
end;

function TpvVulkanDescriptorSetLayoutBinding.GetStageFlags:TVkShaderStageFlags;
begin
 result:=fDescriptorSetLayoutBinding.stageFlags;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.SetStageFlags(const aStageFlags:TVkShaderStageFlags);
begin
 fDescriptorSetLayoutBinding.stageFlags:=aStageFlags;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.AddImmutableSampler(const aImmutableSampler:TpvVulkanSampler);
var Index:TpvInt32;
begin
 Index:=fCountImmutableSamplers;
 inc(fCountImmutableSamplers);
 if fCountImmutableSamplers>length(fImmutableSamplers) then begin
  SetLength(fImmutableSamplers,fCountImmutableSamplers*2);
 end;
 fImmutableSamplers[Index]:=aImmutableSampler.fSamplerHandle;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.AddImmutableSamplers(const aImmutableSamplers:array of TpvVulkanSampler);
var Index:TpvInt32;
begin
 for Index:=0 to length(aImmutableSamplers)-1 do begin
  AddImmutableSampler(aImmutableSamplers[Index]);
 end;
end;

procedure TpvVulkanDescriptorSetLayoutBinding.Initialize;
begin
 SetLength(fImmutableSamplers,fCountImmutableSamplers);
 fDescriptorSetLayoutBinding.pImmutableSamplers:=@fImmutableSamplers[0];
end;

constructor TpvVulkanDescriptorSetLayout.Create(const aDevice:TpvVulkanDevice);
begin
 inherited Create;

 fDevice:=aDevice;

 fDescriptorSetLayoutHandle:=VK_NULL_HANDLE;

 fDescriptorSetLayoutBindingList:=TpvVulkanObjectList.Create;
 fDescriptorSetLayoutBindingList.OwnObjects:=true;

 fDescriptorSetLayoutBindingArray:=nil;

end;

destructor TpvVulkanDescriptorSetLayout.Destroy;
begin
 if fDescriptorSetLayoutHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyDescriptorSetLayout(fDevice.fDeviceHandle,fDescriptorSetLayoutHandle,fDevice.fAllocationCallbacks);
  fDescriptorSetLayoutHandle:=VK_NULL_HANDLE;
 end;
 FreeAndNil(fDescriptorSetLayoutBindingList);
 SetLength(fDescriptorSetLayoutBindingArray,0);
 inherited Destroy;
end;

procedure TpvVulkanDescriptorSetLayout.AddBinding(const aBinding:TpvUInt32;
                                                  const aDescriptorType:TVkDescriptorType;
                                                  const aDescriptorCount:TpvUInt32;
                                                  const aStageFlags:TVkShaderStageFlags;
                                                  const aImmutableSamplers:array of TpvVulkanSampler);
var DescriptorSetLayoutBinding:TpvVulkanDescriptorSetLayoutBinding;
begin
 DescriptorSetLayoutBinding:=TpvVulkanDescriptorSetLayoutBinding.Create(aBinding,aDescriptorType,aDescriptorCount,aStageFlags);
 fDescriptorSetLayoutBindingList.Add(DescriptorSetLayoutBinding);
 DescriptorSetLayoutBinding.AddImmutableSamplers(aImmutableSamplers);
 DescriptorSetLayoutBinding.Initialize;
end;

procedure TpvVulkanDescriptorSetLayout.Initialize;
var Index:TpvInt32;
    DescriptorSetLayoutCreateInfo:TVkDescriptorSetLayoutCreateInfo;
begin
 if fDescriptorSetLayoutHandle=VK_NULL_HANDLE then begin
  FillChar(DescriptorSetLayoutCreateInfo,SizeOf(TVkDescriptorSetLayoutCreateInfo),#0);
  DescriptorSetLayoutCreateInfo.sType:=VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
  SetLength(fDescriptorSetLayoutBindingArray,fDescriptorSetLayoutBindingList.Count);
  if length(fDescriptorSetLayoutBindingArray)>0 then begin
   for Index:=0 to length(fDescriptorSetLayoutBindingArray)-1 do begin
    fDescriptorSetLayoutBindingArray[Index]:=TpvVulkanDescriptorSetLayoutBinding(fDescriptorSetLayoutBindingList[Index]).fDescriptorSetLayoutBinding;
   end;
   DescriptorSetLayoutCreateInfo.bindingCount:=length(fDescriptorSetLayoutBindingArray);
   DescriptorSetLayoutCreateInfo.pBindings:=@fDescriptorSetLayoutBindingArray[0];
  end;
  HandleResultCode(fDevice.fDeviceVulkan.CreateDescriptorSetLayout(fDevice.fDeviceHandle,@DescriptorSetLayoutCreateInfo,fDevice.fAllocationCallbacks,@fDescriptorSetLayoutHandle));
 end;
end;

constructor TpvVulkanDescriptorSet.Create(const aDescriptorPool:TpvVulkanDescriptorPool;
                                          const aDescriptorSetLayout:TpvVulkanDescriptorSetLayout);
begin
 inherited Create;

 fDevice:=aDescriptorPool.fDevice;

 fDescriptorPool:=aDescriptorPool;

 fDescriptorSetLayout:=aDescriptorSetLayout;

 fDescriptorSetHandle:=VK_NULL_HANDLE;

 fCopyDescriptorSetQueue:=nil;
 fCopyDescriptorSetQueueSize:=0;

 fWriteDescriptorSetQueue:=nil;
 fWriteDescriptorSetQueueMetaData:=nil;
 fWriteDescriptorSetQueueSize:=0;

 FillChar(fDescriptorSetAllocateInfo,SizeOf(TVkDescriptorSetAllocateInfo),#0);
 fDescriptorSetAllocateInfo.sType:=VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
 fDescriptorSetAllocateInfo.descriptorPool:=fDescriptorPool.fDescriptorPoolHandle;
 fDescriptorSetAllocateInfo.descriptorSetCount:=1;
 fDescriptorSetAllocateInfo.pSetLayouts:=@fDescriptorSetLayout.fDescriptorSetLayoutHandle;

 fDevice.fDeviceVulkan.AllocateDescriptorSets(fDevice.fDeviceHandle,@fDescriptorSetAllocateInfo,@fDescriptorSetHandle);

end;

destructor TpvVulkanDescriptorSet.Destroy;
begin
 if fDescriptorSetHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.FreeDescriptorSets(fDevice.fDeviceHandle,fDescriptorPool.fDescriptorPoolHandle,1,@fDescriptorSetHandle);
  fDescriptorSetHandle:=VK_NULL_HANDLE;
 end;
 SetLength(fCopyDescriptorSetQueue,0);
 SetLength(fWriteDescriptorSetQueue,0);
 SetLength(fWriteDescriptorSetQueueMetaData,0);
 inherited Destroy;
end;

class function TpvVulkanDescriptorSet.Allocate(const aDescriptorPool:TpvVulkanDescriptorPool;
                                               const aDescriptorSetLayouts:array of TpvVulkanDescriptorSetLayout):TpvVulkanObjectList;
var Index:TpvInt32;
begin
 result:=TpvVulkanObjectList.Create;
 try
  for Index:=0 to length(aDescriptorSetLayouts)-1 do begin
   result.Add(TpvVulkanDescriptorSet.Create(aDescriptorPool,aDescriptorSetLayouts[Index]));
  end;
 except
  FreeAndNil(result);
  raise;
 end;
end;

procedure TpvVulkanDescriptorSet.CopyFromDescriptorSet(const aSourceDescriptorSet:TpvVulkanDescriptorSet;
                                                       const aSourceBinding:TpvUInt32;
                                                       const aSourceArrayElement:TpvUInt32;
                                                       const aDestinationBinding:TpvUInt32;
                                                       const aDestinationArrayElement:TpvUInt32;
                                                       const aDescriptorCount:TpvUInt32;
                                                       const aDoInstant:boolean=false);
 procedure InstantCopyFromDescriptorSet;
 var CopyDescriptorSet:TVkCopyDescriptorSet;
 begin
  FillChar(CopyDescriptorSet,SizeOf(TVkCopyDescriptorSet),#0);
  CopyDescriptorSet.sType:=VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET;
  CopyDescriptorSet.srcSet:=aSourceDescriptorSet.Handle;
  CopyDescriptorSet.srcBinding:=aSourceBinding;
  CopyDescriptorSet.srcArrayElement:=aSourceArrayElement;
  CopyDescriptorSet.dstBinding:=aDestinationBinding;
  CopyDescriptorSet.dstArrayElement:=aDestinationArrayElement;
  CopyDescriptorSet.descriptorCount:=aDescriptorCount;
  fDevice.fDeviceVulkan.UpdateDescriptorSets(fDevice.fDeviceHandle,0,nil,1,@CopyDescriptorSet);
 end;
var Index:TpvInt32;
    CopyDescriptorSet:PVkCopyDescriptorSet;
begin
 if aDoInstant then begin
  InstantCopyFromDescriptorSet; 
 end else begin
  Index:=fCopyDescriptorSetQueueSize;
  inc(fCopyDescriptorSetQueueSize);
  if length(fCopyDescriptorSetQueue)<fCopyDescriptorSetQueueSize then begin
   SetLength(fCopyDescriptorSetQueue,fCopyDescriptorSetQueueSize*2);
  end;
  CopyDescriptorSet:=@fCopyDescriptorSetQueue[Index];
  FillChar(CopyDescriptorSet^,SizeOf(TVkCopyDescriptorSet),#0);
  CopyDescriptorSet^.sType:=VK_STRUCTURE_TYPE_COPY_DESCRIPTOR_SET;
  CopyDescriptorSet^.srcSet:=aSourceDescriptorSet.Handle;
  CopyDescriptorSet^.srcBinding:=aSourceBinding;
  CopyDescriptorSet^.srcArrayElement:=aSourceArrayElement;
  CopyDescriptorSet^.dstBinding:=aDestinationBinding;
  CopyDescriptorSet^.dstArrayElement:=aDestinationArrayElement;
  CopyDescriptorSet^.descriptorCount:=aDescriptorCount;
 end;
end;

procedure TpvVulkanDescriptorSet.WriteToDescriptorSet(const aDestinationBinding:TpvUInt32;
                                                      const aDestinationArrayElement:TpvUInt32;
                                                      const aDescriptorCount:TpvUInt32;
                                                      const aDescriptorType:TVkDescriptorType;
                                                      const aImageInfo:array of TVkDescriptorImageInfo;
                                                      const aBufferInfo:array of TVkDescriptorBufferInfo;
                                                      const aTexelBufferView:array of TVkBufferView;
                                                      const aDoInstant:boolean=false);
 procedure InstantWriteToDescriptorSet;
 var WriteDescriptorSet:TVkWriteDescriptorSet;
 begin
  FillChar(WriteDescriptorSet,SizeOf(TVkWriteDescriptorSet),#0);
  WriteDescriptorSet.sType:=VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  WriteDescriptorSet.dstSet:=fDescriptorSetHandle;
  WriteDescriptorSet.dstBinding:=aDestinationBinding;
  WriteDescriptorSet.dstArrayElement:=aDestinationArrayElement;
  WriteDescriptorSet.descriptorType:=aDescriptorType;
  WriteDescriptorSet.descriptorCount:=aDescriptorCount;
  if length(aImageInfo)>0 then begin
   WriteDescriptorSet.pImageInfo:=@aImageInfo[0];
  end else begin
   WriteDescriptorSet.pImageInfo:=nil;
  end;
  if length(aBufferInfo)>0 then begin
   WriteDescriptorSet.pBufferInfo:=@aBufferInfo[0];
  end else begin
   WriteDescriptorSet.pBufferInfo:=nil;
  end;
  if length(aTexelBufferView)>0 then begin
   WriteDescriptorSet.pTexelBufferView:=@aTexelBufferView[0];
  end else begin
   WriteDescriptorSet.pTexelBufferView:=nil;
  end;
  fDevice.fDeviceVulkan.UpdateDescriptorSets(fDevice.fDeviceHandle,1,@WriteDescriptorSet,0,nil);
 end;
var Index:TpvInt32;
    WriteDescriptorSet:PVkWriteDescriptorSet;
    WriteDescriptorSetMetaData:PpvVulkanDescriptorSetWriteDescriptorSetMetaData;
begin
 if aDoInstant then begin
  InstantWriteToDescriptorSet;
 end else begin
  Index:=fWriteDescriptorSetQueueSize;
  inc(fWriteDescriptorSetQueueSize);
  if length(fWriteDescriptorSetQueue)<fWriteDescriptorSetQueueSize then begin
   SetLength(fWriteDescriptorSetQueue,fWriteDescriptorSetQueueSize*2);
  end;
  if length(fWriteDescriptorSetQueueMetaData)<fWriteDescriptorSetQueueSize then begin
   SetLength(fWriteDescriptorSetQueueMetaData,fWriteDescriptorSetQueueSize*2);
  end;
  WriteDescriptorSet:=@fWriteDescriptorSetQueue[Index];
  WriteDescriptorSetMetaData:=@fWriteDescriptorSetQueueMetaData[Index];
  FillChar(WriteDescriptorSet^,SizeOf(TVkWriteDescriptorSet),#0);
  WriteDescriptorSet^.sType:=VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
  WriteDescriptorSet^.dstSet:=fDescriptorSetHandle;
  WriteDescriptorSet^.dstBinding:=aDestinationBinding;
  WriteDescriptorSet^.dstArrayElement:=aDestinationArrayElement;
  WriteDescriptorSet^.descriptorType:=aDescriptorType;
  WriteDescriptorSet^.descriptorCount:=aDescriptorCount;
  WriteDescriptorSet^.pImageInfo:=nil;
  WriteDescriptorSet^.pBufferInfo:=nil;
  WriteDescriptorSet^.pTexelBufferView:=nil;
  WriteDescriptorSetMetaData^.ImageInfo:=nil;
  WriteDescriptorSetMetaData^.BufferInfo:=nil;
  WriteDescriptorSetMetaData^.TexelBufferView:=nil;
  if length(aImageInfo)>0 then begin
   SetLength(WriteDescriptorSetMetaData^.ImageInfo,length(aImageInfo));
   Move(aImageInfo[0],WriteDescriptorSetMetaData^.ImageInfo[0],length(aImageInfo)*SizeOf(TVkDescriptorImageInfo));
  end;
  if length(aBufferInfo)>0 then begin
   SetLength(WriteDescriptorSetMetaData^.BufferInfo,length(aBufferInfo));
   Move(aBufferInfo[0],WriteDescriptorSetMetaData^.BufferInfo[0],length(aBufferInfo)*SizeOf(TVkDescriptorBufferInfo));
  end;
  if length(aTexelBufferView)>0 then begin
   SetLength(WriteDescriptorSetMetaData^.TexelBufferView,length(aTexelBufferView));
   Move(aTexelBufferView[0],WriteDescriptorSetMetaData^.TexelBufferView[0],length(aTexelBufferView)*SizeOf(TVkBufferView));
  end;
 end;
end;

procedure TpvVulkanDescriptorSet.Flush;
var Index:TpvInt32;
    WriteDescriptorSet:PVkWriteDescriptorSet;
    WriteDescriptorSetMetaData:PpvVulkanDescriptorSetWriteDescriptorSetMetaData;
begin
 if fWriteDescriptorSetQueueSize>0 then begin
  for Index:=0 to fWriteDescriptorSetQueueSize-1 do begin
   WriteDescriptorSet:=@fWriteDescriptorSetQueue[Index];
   WriteDescriptorSetMetaData:=@fWriteDescriptorSetQueueMetaData[Index];
   if length(WriteDescriptorSetMetaData^.ImageInfo)>0 then begin
    WriteDescriptorSet^.pImageInfo:=@WriteDescriptorSetMetaData^.ImageInfo[0];
   end else begin
    WriteDescriptorSet^.pImageInfo:=nil;
   end;
   if length(WriteDescriptorSetMetaData^.BufferInfo)>0 then begin
    WriteDescriptorSet^.pBufferInfo:=@WriteDescriptorSetMetaData^.BufferInfo[0];
   end else begin
    WriteDescriptorSet^.pBufferInfo:=nil;
   end;
   if length(WriteDescriptorSetMetaData^.TexelBufferView)>0 then begin
    WriteDescriptorSet^.pTexelBufferView:=@WriteDescriptorSetMetaData^.TexelBufferView[0];
   end else begin
    WriteDescriptorSet^.pTexelBufferView:=nil;
   end;
  end;
  if fCopyDescriptorSetQueueSize>0 then begin
   fDevice.fDeviceVulkan.UpdateDescriptorSets(fDevice.fDeviceHandle,fWriteDescriptorSetQueueSize,@fWriteDescriptorSetQueue[0],fCopyDescriptorSetQueueSize,@fCopyDescriptorSetQueue[0]);
  end else begin
   fDevice.fDeviceVulkan.UpdateDescriptorSets(fDevice.fDeviceHandle,fWriteDescriptorSetQueueSize,@fWriteDescriptorSetQueue[0],0,nil);
  end;
 end else if fCopyDescriptorSetQueueSize>0 then begin
  fDevice.fDeviceVulkan.UpdateDescriptorSets(fDevice.fDeviceHandle,0,nil,fCopyDescriptorSetQueueSize,@fCopyDescriptorSetQueue[0]);
 end;
 fCopyDescriptorSetQueueSize:=0;
 fWriteDescriptorSetQueueSize:=0;
end;

constructor TpvVulkanPipelineLayout.Create(const aDevice:TpvVulkanDevice);
begin

 inherited Create;

 fDevice:=aDevice;

 fPipelineLayoutHandle:=VK_NULL_HANDLE;

 fDescriptorSetLayouts:=nil;
 fCountDescriptorSetLayouts:=0;

 fPushConstantRanges:=nil;
 fCountPushConstantRanges:=0;

end;

destructor TpvVulkanPipelineLayout.Destroy;
begin
 if fPipelineLayoutHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyPipelineLayout(fDevice.fDeviceHandle,fPipelineLayoutHandle,fDevice.fAllocationCallbacks);
  fPipelineLayoutHandle:=VK_NULL_HANDLE;
 end;
 SetLength(fDescriptorSetLayouts,0);
 SetLength(fPushConstantRanges,0);
 inherited Destroy;
end;

function TpvVulkanPipelineLayout.AddDescriptorSetLayout(const aDescriptorSetLayout:TVkDescriptorSetLayout):TpvInt32;
begin
 result:=fCountDescriptorSetLayouts;
 inc(fCountDescriptorSetLayouts);
 if fCountDescriptorSetLayouts>length(fDescriptorSetLayouts) then begin
  SetLength(fDescriptorSetLayouts,fCountDescriptorSetLayouts*2);
 end;
 fDescriptorSetLayouts[result]:=aDescriptorSetLayout;
end;

function TpvVulkanPipelineLayout.AddDescriptorSetLayout(const aDescriptorSetLayout:TpvVulkanDescriptorSetLayout):TpvInt32;
begin
 result:=fCountDescriptorSetLayouts;
 inc(fCountDescriptorSetLayouts);
 if fCountDescriptorSetLayouts>length(fDescriptorSetLayouts) then begin
  SetLength(fDescriptorSetLayouts,fCountDescriptorSetLayouts*2);
 end;
 fDescriptorSetLayouts[result]:=aDescriptorSetLayout.fDescriptorSetLayoutHandle;
end;

function TpvVulkanPipelineLayout.AddDescriptorSetLayouts(const aDescriptorSetLayouts:array of TVkDescriptorSetLayout):TpvInt32;
begin
 if length(aDescriptorSetLayouts)>0 then begin
  result:=fCountDescriptorSetLayouts;
  inc(fCountDescriptorSetLayouts,length(aDescriptorSetLayouts));
  if fCountDescriptorSetLayouts>length(fDescriptorSetLayouts) then begin
   SetLength(fDescriptorSetLayouts,fCountDescriptorSetLayouts*2);
  end;
  Move(aDescriptorSetLayouts[0],fDescriptorSetLayouts[result],length(aDescriptorSetLayouts)*SizeOf(TVkDescriptorSetLayout));
 end else begin
  result:=-1;
 end;
end;

function TpvVulkanPipelineLayout.AddDescriptorSetLayouts(const aDescriptorSetLayouts:array of TpvVulkanDescriptorSetLayout):TpvInt32;
var Index:TpvInt32;
begin
 if length(aDescriptorSetLayouts)>0 then begin
  result:=fCountDescriptorSetLayouts;
  inc(fCountDescriptorSetLayouts,length(aDescriptorSetLayouts));
  if fCountDescriptorSetLayouts>length(fDescriptorSetLayouts) then begin
   SetLength(fDescriptorSetLayouts,fCountDescriptorSetLayouts*2);
  end;
  for Index:=0 to length(aDescriptorSetLayouts)-1 do begin
   fDescriptorSetLayouts[result+Index]:=aDescriptorSetLayouts[Index].fDescriptorSetLayoutHandle;
  end;
 end else begin
  result:=-1;
 end;
end;

function TpvVulkanPipelineLayout.AddPushConstantRange(const aPushConstantRange:TVkPushConstantRange):TpvInt32;
begin
 result:=fCountPushConstantRanges;
 inc(fCountPushConstantRanges);
 if fCountPushConstantRanges>length(fPushConstantRanges) then begin
  SetLength(fPushConstantRanges,fCountPushConstantRanges*2);
 end;
 fPushConstantRanges[result]:=aPushConstantRange;
end;

function TpvVulkanPipelineLayout.AddPushConstantRange(const aStageFlags:TVkShaderStageFlags;const aOffset,aSize:TpvUInt32):TpvInt32;
var PushConstantRange:PVkPushConstantRange;
begin
 result:=fCountPushConstantRanges;
 inc(fCountPushConstantRanges);
 if fCountPushConstantRanges>length(fPushConstantRanges) then begin
  SetLength(fPushConstantRanges,fCountPushConstantRanges*2);
 end;
 PushConstantRange:=@fPushConstantRanges[result];
 PushConstantRange^.stageFlags:=aStageFlags;
 PushConstantRange^.offset:=aOffset;
 PushConstantRange^.size:=aSize;
end;

function TpvVulkanPipelineLayout.AddPushConstantRanges(const aPushConstantRanges:array of TVkPushConstantRange):TpvInt32;
begin
 if length(aPushConstantRanges)>0 then begin
  result:=fCountPushConstantRanges;
  inc(fCountPushConstantRanges,length(aPushConstantRanges));
  if fCountPushConstantRanges>length(fPushConstantRanges) then begin
   SetLength(fPushConstantRanges,fCountPushConstantRanges*2);
  end;
  Move(aPushConstantRanges[0],fPushConstantRanges[result],length(aPushConstantRanges)*SizeOf(TVkPushConstantRange));
 end else begin
  result:=-1;
 end;
end;

procedure TpvVulkanPipelineLayout.Initialize;
var PipelineLayoutCreateInfo:TVkPipelineLayoutCreateInfo;
begin

 if fPipelineLayoutHandle=VK_NULL_HANDLE then begin

  FillChar(PipelineLayoutCreateInfo,SizeOf(TVkPipelineLayoutCreateInfo),#0);
  PipelineLayoutCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
  PipelineLayoutCreateInfo.pNext:=nil;
  PipelineLayoutCreateInfo.flags:=0;
  PipelineLayoutCreateInfo.setLayoutCount:=0;
  PipelineLayoutCreateInfo.pSetLayouts:=nil;
  PipelineLayoutCreateInfo.pushConstantRangeCount:=0;
  PipelineLayoutCreateInfo.pPushConstantRanges:=nil;
  
  SetLength(fDescriptorSetLayouts,fCountDescriptorSetLayouts);
  PipelineLayoutCreateInfo.setLayoutCount:=fCountDescriptorSetLayouts;
  if fCountDescriptorSetLayouts>0 then begin
   PipelineLayoutCreateInfo.pSetLayouts:=@fDescriptorSetLayouts[0];
  end else begin
   PipelineLayoutCreateInfo.pSetLayouts:=nil;
  end;

  SetLength(fPushConstantRanges,fCountPushConstantRanges);
  PipelineLayoutCreateInfo.pushConstantRangeCount:=fCountPushConstantRanges;
  if fCountPushConstantRanges>0 then begin
   PipelineLayoutCreateInfo.pPushConstantRanges:=@fPushConstantRanges[0];
  end else begin
   PipelineLayoutCreateInfo.pPushConstantRanges:=nil;
  end;

  HandleResultCode(fDevice.fDeviceVulkan.CreatePipelineLayout(fDevice.fDeviceHandle,@PipelineLayoutCreateInfo,fDevice.fAllocationCallbacks,@fPipelineLayoutHandle));

 end;

end;

constructor TpvVulkanPipelineShaderStage.Create(const aStage:TVkShaderStageFlagBits;
                                                const aModule:TpvVulkanShaderModule;
                                                const aName:TVkCharString);
begin

 inherited Create;

 fName:=aName;

 FillChar(fPipelineShaderStageCreateInfo,SizeOf(TVkPipelineShaderStageCreateInfo),#0);
 fPipelineShaderStageCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
 fPipelineShaderStageCreateInfo.pNext:=nil;
 fPipelineShaderStageCreateInfo.flags:=0;
 fPipelineShaderStageCreateInfo.stage:=aStage;
 fPipelineShaderStageCreateInfo.module:=aModule.fShaderModuleHandle;
 fPipelineShaderStageCreateInfo.pName:=PVkChar(fName);
 fPipelineShaderStageCreateInfo.pSpecializationInfo:=nil;

 fPointerToPipelineShaderStageCreateInfo:=@fPipelineShaderStageCreateInfo;

 fSpecializationInfo:=nil;

 fDoCopyAndDoFree:=false;

 fSpecializationMapEntries:=nil;
 fCountSpecializationMapEntries:=0;

 fInitialized:=false;

end;

destructor TpvVulkanPipelineShaderStage.Destroy;
begin
 fName:='';
 if assigned(fSpecializationInfo) then begin
  if assigned(fSpecializationInfo.pData) and fDoCopyAndDoFree then begin
   FreeMem(fSpecializationInfo.pData);
   fSpecializationInfo.pData:=nil;
   fSpecializationInfo.dataSize:=0;
  end;
  FreeMem(fSpecializationInfo);
  fSpecializationInfo:=nil;
 end;
 SetLength(fSpecializationMapEntries,0);
 inherited Destroy;
end;

procedure TpvVulkanPipelineShaderStage.AllocateSpecializationInfo;
begin
 if not assigned(fSpecializationInfo) then begin
  GetMem(fSpecializationInfo,SizeOf(TVkSpecializationInfo));
  FillChar(fSpecializationInfo^,SizeOf(TVkSpecializationInfo),#0);
  fPipelineShaderStageCreateInfo.pSpecializationInfo:=fSpecializationInfo;
 end;
end;

procedure TpvVulkanPipelineShaderStage.AddSpecializationDataFromMemory(const aData:TpvPointer;const aDataSize:TVkSize;const aDoCopyAndDoFree:boolean=true);
begin
 if assigned(fSpecializationInfo) and assigned(fSpecializationInfo.pData) and fDoCopyAndDoFree then begin
  FreeMem(fSpecializationInfo.pData);
  fSpecializationInfo.pData:=nil;
  fSpecializationInfo.dataSize:=0;
 end;
 if assigned(aData) and (aDataSize>0) then begin
  AllocateSpecializationInfo;
  fDoCopyAndDoFree:=aDoCopyAndDoFree;
  if fDoCopyAndDoFree then begin
   GetMem(fSpecializationInfo.pData,aDataSize);
   Move(aData^,fSpecializationInfo.pData^,aDataSize);
  end else begin
   fSpecializationInfo.pData:=aData;
  end;
  fSpecializationInfo.dataSize:=aDataSize;
 end;
end;

procedure TpvVulkanPipelineShaderStage.AddSpecializationDataFromStream(const aStream:TStream);
begin
 if assigned(fSpecializationInfo) and assigned(fSpecializationInfo.pData) and fDoCopyAndDoFree then begin
  FreeMem(fSpecializationInfo.pData);
  fSpecializationInfo.pData:=nil;
  fSpecializationInfo.dataSize:=0;
 end;
 if assigned(aStream) and (aStream.Size>0) then begin
  AllocateSpecializationInfo;
  fDoCopyAndDoFree:=true;
  GetMem(fSpecializationInfo.pData,aStream.Size);
  if aStream.Seek(0,soBeginning)<>0 then begin
   raise EInOutError.Create('Stream seek error');
  end;
  if aStream.Read(fSpecializationInfo.pData^,aStream.Size)<>aStream.Size then begin
   raise EInOutError.Create('Stream read error');
  end;
  fSpecializationInfo.dataSize:=aStream.Size;
 end;
end;

procedure TpvVulkanPipelineShaderStage.AddSpecializationDataFromFile(const aFileName:string);
var FileStream:TFileStream;
begin
 FileStream:=TFileStream.Create(aFileName,fmOpenRead or fmShareDenyWrite);
 try
  AddSpecializationDataFromStream(FileStream);
 finally
  FileStream.Free;
 end;
end;

function TpvVulkanPipelineShaderStage.AddSpecializationMapEntry(const aSpecializationMapEntry:TVkSpecializationMapEntry):TpvInt32;
begin
 result:=fCountSpecializationMapEntries;
 inc(fCountSpecializationMapEntries);
 if length(fSpecializationMapEntries)<fCountSpecializationMapEntries then begin
  SetLength(fSpecializationMapEntries,fCountSpecializationMapEntries*2);
 end;
 fSpecializationMapEntries[result]:=aSpecializationMapEntry;
end;

function TpvVulkanPipelineShaderStage.AddSpecializationMapEntry(const aConstantID,aOffset:TpvUInt32;const aSize:TVkSize):TpvInt32;
var SpecializationMapEntry:PVkSpecializationMapEntry;
begin
 result:=fCountSpecializationMapEntries;
 inc(fCountSpecializationMapEntries);
 if length(fSpecializationMapEntries)<fCountSpecializationMapEntries then begin
  SetLength(fSpecializationMapEntries,fCountSpecializationMapEntries*2);
 end;
 SpecializationMapEntry:=@fSpecializationMapEntries[result];
 SpecializationMapEntry^.constantID:=aConstantID;
 SpecializationMapEntry^.offset:=aOffset;
 SpecializationMapEntry^.size:=aSize;
end;

function TpvVulkanPipelineShaderStage.AddSpecializationMapEntries(const aSpecializationMapEntries:array of TVkSpecializationMapEntry):TpvInt32;
begin
 if length(aSpecializationMapEntries)>0 then begin
  result:=fCountSpecializationMapEntries;
  inc(fCountSpecializationMapEntries,length(aSpecializationMapEntries));
  if length(fSpecializationMapEntries)<fCountSpecializationMapEntries then begin
   SetLength(fSpecializationMapEntries,fCountSpecializationMapEntries*2);
  end;
  Move(aSpecializationMapEntries[0],fSpecializationMapEntries[result],length(aSpecializationMapEntries)*SizeOf(TVkSpecializationMapEntry));
 end else begin
  result:=-1;
 end;
end;

procedure TpvVulkanPipelineShaderStage.Initialize;
begin
 if not fInitialized then begin
  fInitialized:=true;
  if fCountSpecializationMapEntries>0 then begin
   AllocateSpecializationInfo;
   SetLength(fSpecializationMapEntries,fCountSpecializationMapEntries);
   fSpecializationInfo^.mapEntryCount:=fCountSpecializationMapEntries;
   fSpecializationInfo^.pMapEntries:=@fSpecializationMapEntries[0];
  end;
 end;
end;

constructor TpvVulkanPipelineCache.Create(const aDevice:TpvVulkanDevice;const aInitialData:TpvPointer=nil;const aInitialDataSize:TVkSize=0);
var PipelineCacheCreateInfo:TVkPipelineCacheCreateInfo;
begin
 inherited Create;

 fDevice:=aDevice;

 fPipelineCacheHandle:=VK_NULL_HANDLE;

 FillChar(PipelineCacheCreateInfo,SizeOf(TVkPipelineCacheCreateInfo),#0);
 PipelineCacheCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_CACHE_CREATE_INFO;
 PipelineCacheCreateInfo.pNext:=nil;
 PipelineCacheCreateInfo.flags:=0;
 PipelineCacheCreateInfo.pInitialData:=aInitialData;
 PipelineCacheCreateInfo.initialDataSize:=aInitialDataSize;

 HandleResultCode(fDevice.fDeviceVulkan.CreatePipelineCache(fDevice.fDeviceHandle,@PipelineCacheCreateInfo,fDevice.fAllocationCallbacks,@fPipelineCacheHandle));

end;

constructor TpvVulkanPipelineCache.CreateFromMemory(const aDevice:TpvVulkanDevice;const aInitialData:TpvPointer;const aInitialDataSize:TVkSize);
type PByteArray=^TByteArray;
     TByteArray=array[0..65535] of TpvUInt8;
var Index:TpvInt32;
begin
 if not assigned(aInitialData) then begin
  raise EInOutError.Create('aInitialData is null');
 end else if aInitialDataSize<VK_UUID_SIZE then begin
  raise EInOutError.Create('Data too small');
 end else if not CompareMem(@PpvVulkanUUID(aInitialData)^[0],@aDevice.fPhysicalDevice.fProperties.pipelineCacheUUID,SizeOf(TpvVulkanUUID)) then begin
  raise EpvVulkanPipelineCacheException.Create('Pipeline cache dump is not compatible with the current physical device');
 end else begin
  Create(aDevice,@PByteArray(aInitialData)^[SizeOf(TpvVulkanUUID)],aInitialDataSize-SizeOf(TpvVulkanUUID));
 end;
end;

constructor TpvVulkanPipelineCache.CreateFromStream(const aDevice:TpvVulkanDevice;const aStream:TStream);
var Data:TpvPointer;
    DataSize:TVkSize;
begin
 fPipelineCacheHandle:=VK_NULL_HANDLE;
 if assigned(aStream) and (aStream.Size>0) then begin
  DataSize:=aStream.Size;
  GetMem(Data,DataSize);
  try
   if aStream.Seek(0,soBeginning)<>0 then begin
    raise EInOutError.Create('Stream seek error');
   end;
   if aStream.Read(Data^,aStream.Size)<>aStream.Size then begin
    raise EInOutError.Create('Stream read error');
   end;
   CreateFromMemory(aDevice,Data,DataSize);
  finally
   FreeMem(Data);
  end;
 end;
end;

constructor TpvVulkanPipelineCache.CreateFromFile(const aDevice:TpvVulkanDevice;const aFileName:string);
var FileStream:TFileStream;
begin
 fPipelineCacheHandle:=VK_NULL_HANDLE;
 FileStream:=TFileStream.Create(aFileName,fmOpenRead or fmShareDenyWrite);
 try
  CreateFromStream(aDevice,FileStream);
 finally
  FileStream.Free;
 end;
end;

destructor TpvVulkanPipelineCache.Destroy;
begin
 if fPipelineCacheHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyPipelineCache(fDevice.fDeviceHandle,fPipelineCacheHandle,fDevice.fAllocationCallbacks);
  fPipelineCacheHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

procedure TpvVulkanPipelineCache.SaveToStream(const aStream:TStream);
var Data:TpvPointer;
    DataSize:TVKSize;
begin
 HandleResultCode(fDevice.fDeviceVulkan.GetPipelineCacheData(fDevice.fDeviceHandle,fPipelineCacheHandle,@DataSize,nil));
 if DataSize>0 then begin
  GetMem(Data,DataSize);
  try
   HandleResultCode(fDevice.fDeviceVulkan.GetPipelineCacheData(fDevice.fDeviceHandle,fPipelineCacheHandle,@DataSize,Data));
   if aStream.Write(fDevice.fPhysicalDevice.fProperties.pipelineCacheUUID,SizeOf(TpvVulkanUUID))<>SizeOf(TpvVulkanUUID) then begin
    raise EInOutError.Create('Stream write error');
   end;
   if aStream.Write(Data^,DataSize)<>TpvPtrInt(DataSize) then begin
    raise EInOutError.Create('Stream write error');
   end;
  finally
   FreeMem(Data);
  end;
 end;
end;

procedure TpvVulkanPipelineCache.SaveToFile(const aFileName:string);
var FileStream:TFileStream;
begin
 FileStream:=TFileStream.Create(aFileName,fmCreate);
 try
  SaveToStream(FileStream);
 finally
  FileStream.Free;
 end;
end;

procedure TpvVulkanPipelineCache.Merge(const aSourcePipelineCache:TpvVulkanPipelineCache);
begin
 HandleResultCode(fDevice.fDeviceVulkan.MergePipelineCaches(fDevice.fDeviceHandle,fPipelineCacheHandle,1,@aSourcePipelineCache.fPipelineCacheHandle));
end;

procedure TpvVulkanPipelineCache.Merge(const aSourcePipelineCaches:array of TpvVulkanPipelineCache);
var Index:TpvInt32;
    SourcePipelineCaches:TVkPipelineCacheArray;
begin
 if length(aSourcePipelineCaches)>0 then begin
  SourcePipelineCaches:=nil;
  try
   SetLength(SourcePipelineCaches,length(aSourcePipelineCaches));
   for Index:=0 to length(aSourcePipelineCaches)-1 do begin
    SourcePipelineCaches[Index]:=aSourcePipelineCaches[Index].fPipelineCacheHandle;
   end;
   HandleResultCode(fDevice.fDeviceVulkan.MergePipelineCaches(fDevice.fDeviceHandle,fPipelineCacheHandle,length(SourcePipelineCaches),@SourcePipelineCaches[0]));
  finally
   SetLength(SourcePipelineCaches,0);
  end;
 end;
end;

constructor TpvVulkanPipeline.Create(const aDevice:TpvVulkanDevice);
begin
 inherited Create;
 fDevice:=aDevice;
 fPipelineHandle:=VK_NULL_HANDLE;
end;

destructor TpvVulkanPipeline.Destroy;
begin
 if fPipelineHandle<>VK_NULL_HANDLE then begin
  fDevice.fDeviceVulkan.DestroyPipeline(fDevice.fDeviceHandle,fPipelineHandle,fDevice.fAllocationCallbacks);
  fPipelineHandle:=VK_NULL_HANDLE;
 end;
 inherited Destroy;
end;

constructor TpvVulkanComputePipeline.Create(const aDevice:TpvVulkanDevice;
                                            const aCache:TpvVulkanPipelineCache;
                                            const aFlags:TVkPipelineCreateFlags;
                                            const aStage:TpvVulkanPipelineShaderStage;
                                            const aLayout:TpvVulkanPipelineLayout;
                                            const aBasePipelineHandle:TpvVulkanPipeline;
                                            const aBasePipelineIndex:TpvInt32);
var PipelineCache:TVkPipelineCache;
    ComputePipelineCreateInfo:TVkComputePipelineCreateInfo;
begin
 inherited Create(aDevice);

 FillChar(ComputePipelineCreateInfo,SizeOf(TVkComputePipelineCreateInfo),#0);
 ComputePipelineCreateInfo.sType:=VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO;
 ComputePipelineCreateInfo.pNext:=nil;
 ComputePipelineCreateInfo.flags:=aFlags;
 if assigned(aStage) then begin
  aStage.Initialize;
  ComputePipelineCreateInfo.stage:=aStage.fPipelineShaderStageCreateInfo;
 end;
 if assigned(aLayout) then begin
  ComputePipelineCreateInfo.layout:=aLayout.fPipelineLayoutHandle;
 end else begin
  ComputePipelineCreateInfo.layout:=VK_NULL_HANDLE;
 end;
 if assigned(aBasePipelineHandle) then begin
  ComputePipelineCreateInfo.basePipelineHandle:=aBasePipelineHandle.fPipelineHandle;
 end else begin
  ComputePipelineCreateInfo.basePipelineHandle:=VK_NULL_HANDLE;
 end;
 ComputePipelineCreateInfo.basePipelineIndex:=aBasePipelineIndex;

 if assigned(aCache) then begin
  PipelineCache:=aCache.fPipelineCacheHandle;
 end else begin
  PipelineCache:=VK_NULL_HANDLE;
 end;

 HandleResultCode(fDevice.fDeviceVulkan.CreateComputePipelines(fDevice.fDeviceHandle,PipelineCache,1,@ComputePipelineCreateInfo,fDevice.fAllocationCallbacks,@fPipelineHandle));

end;

constructor TpvVulkanPipelineState.Create;
begin
 inherited Create;
end;

destructor TpvVulkanPipelineState.Destroy;
begin
 inherited Destroy;
end;

constructor TpvVulkanPipelineVertexInputState.Create;
begin
 inherited Create;

 FillChar(fVertexInputStateCreateInfo,SizeOf(TVkPipelineVertexInputStateCreateInfo),0);
 fVertexInputStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
 fVertexInputStateCreateInfo.pNext:=nil;
 fVertexInputStateCreateInfo.flags:=0;
 fVertexInputStateCreateInfo.vertexBindingDescriptionCount:=0;
 fVertexInputStateCreateInfo.pVertexBindingDescriptions:=nil;
 fVertexInputStateCreateInfo.vertexAttributeDescriptionCount:=0;
 fVertexInputStateCreateInfo.pVertexAttributeDescriptions:=nil;

 fPointerToVertexInputStateCreateInfo:=@fVertexInputStateCreateInfo;

 fVertexInputBindingDescriptions:=nil;
 fCountVertexInputBindingDescriptions:=0;

 fVertexInputAttributeDescriptions:=nil;
 fCountVertexInputAttributeDescriptions:=0;

end;

destructor TpvVulkanPipelineVertexInputState.Destroy;
begin
 SetLength(fVertexInputBindingDescriptions,0);
 SetLength(fVertexInputAttributeDescriptions,0);
 inherited Destroy;
end;

function TpvVulkanPipelineVertexInputState.GetVertexInputBindingDescription(const aIndex:TpvInt32):PVkVertexInputBindingDescription;
begin
 result:=@fVertexInputBindingDescriptions[aIndex];
end;

function TpvVulkanPipelineVertexInputState.GetVertexInputAttributeDescription(const aIndex:TpvInt32):PVkVertexInputAttributeDescription;
begin
 result:=@fVertexInputAttributeDescriptions[aIndex];
end;

procedure TpvVulkanPipelineVertexInputState.SetCountVertexInputBindingDescriptions(const aNewCount:TpvInt32);
begin
 fCountVertexInputBindingDescriptions:=aNewCount;
 if length(fVertexInputBindingDescriptions)<fCountVertexInputBindingDescriptions then begin
  SetLength(fVertexInputBindingDescriptions,fCountVertexInputBindingDescriptions*2);
 end;
end;

procedure TpvVulkanPipelineVertexInputState.SetCountVertexInputAttributeDescriptions(const aNewCount:TpvInt32);
begin
 fCountVertexInputAttributeDescriptions:=aNewCount;
 if length(fVertexInputAttributeDescriptions)<fCountVertexInputAttributeDescriptions then begin
  SetLength(fVertexInputAttributeDescriptions,fCountVertexInputAttributeDescriptions*2);
 end;
end;

procedure TpvVulkanPipelineVertexInputState.Assign(const aFrom:TpvVulkanPipelineVertexInputState);
begin
 fVertexInputBindingDescriptions:=copy(aFrom.fVertexInputBindingDescriptions);
 fCountVertexInputBindingDescriptions:=aFrom.fCountVertexInputBindingDescriptions;
 fVertexInputAttributeDescriptions:=copy(aFrom.fVertexInputAttributeDescriptions);
 fCountVertexInputAttributeDescriptions:=aFrom.fCountVertexInputAttributeDescriptions;
end;

function TpvVulkanPipelineVertexInputState.AddVertexInputBindingDescription(const aVertexInputBindingDescription:TVkVertexInputBindingDescription):TpvInt32;
begin
 result:=fCountVertexInputBindingDescriptions;
 inc(fCountVertexInputBindingDescriptions);
 if length(fVertexInputBindingDescriptions)<fCountVertexInputBindingDescriptions then begin
  SetLength(fVertexInputBindingDescriptions,fCountVertexInputBindingDescriptions*2);
 end;
 fVertexInputBindingDescriptions[result]:=aVertexInputBindingDescription;
end;

function TpvVulkanPipelineVertexInputState.AddVertexInputBindingDescription(const aBinding,aStride:TpvUInt32;const aInputRate:TVkVertexInputRate):TpvInt32;
var VertexInputBindingDescription:PVkVertexInputBindingDescription;
begin
 result:=fCountVertexInputBindingDescriptions;
 inc(fCountVertexInputBindingDescriptions);
 if length(fVertexInputBindingDescriptions)<fCountVertexInputBindingDescriptions then begin
  SetLength(fVertexInputBindingDescriptions,fCountVertexInputBindingDescriptions*2);
 end;
 VertexInputBindingDescription:=@fVertexInputBindingDescriptions[result];
 VertexInputBindingDescription^.binding:=aBinding;
 VertexInputBindingDescription^.stride:=aStride;
 VertexInputBindingDescription^.inputRate:=aInputRate;
end;

function TpvVulkanPipelineVertexInputState.AddVertexInputBindingDescriptions(const aVertexInputBindingDescriptions:array of TVkVertexInputBindingDescription):TpvInt32;
begin
 if length(aVertexInputBindingDescriptions)>0 then begin
  result:=fCountVertexInputBindingDescriptions;
  inc(fCountVertexInputBindingDescriptions,length(aVertexInputBindingDescriptions));
  if length(fVertexInputBindingDescriptions)<fCountVertexInputBindingDescriptions then begin
   SetLength(fVertexInputBindingDescriptions,fCountVertexInputBindingDescriptions*2);
  end;
  Move(aVertexInputBindingDescriptions[0],fVertexInputBindingDescriptions[result],length(aVertexInputBindingDescriptions)*SizeOf(TVkVertexInputBindingDescription));
 end else begin
  result:=-1;
 end;
end;

function TpvVulkanPipelineVertexInputState.AddVertexInputAttributeDescription(const aVertexInputAttributeDescription:TVkVertexInputAttributeDescription):TpvInt32;
begin
 result:=fCountVertexInputAttributeDescriptions;
 inc(fCountVertexInputAttributeDescriptions);
 if length(fVertexInputAttributeDescriptions)<fCountVertexInputAttributeDescriptions then begin
  SetLength(fVertexInputAttributeDescriptions,fCountVertexInputAttributeDescriptions*2);
 end;
 fVertexInputAttributeDescriptions[result]:=aVertexInputAttributeDescription;
end;

function TpvVulkanPipelineVertexInputState.AddVertexInputAttributeDescription(const aLocation,aBinding:TpvUInt32;const aFormat:TVkFormat;const aOffset:TpvUInt32):TpvInt32;
var VertexInputAttributeDescription:PVkVertexInputAttributeDescription;
begin
 result:=fCountVertexInputAttributeDescriptions;
 inc(fCountVertexInputAttributeDescriptions);
 if length(fVertexInputAttributeDescriptions)<fCountVertexInputAttributeDescriptions then begin
  SetLength(fVertexInputAttributeDescriptions,fCountVertexInputAttributeDescriptions*2);
 end;
 VertexInputAttributeDescription:=@fVertexInputAttributeDescriptions[result];
 VertexInputAttributeDescription^.location:=aLocation;
 VertexInputAttributeDescription^.binding:=aBinding;
 VertexInputAttributeDescription^.format:=aFormat;
 VertexInputAttributeDescription^.offset:=aOffset;
end;

function TpvVulkanPipelineVertexInputState.AddVertexInputAttributeDescriptions(const aVertexInputAttributeDescriptions:array of TVkVertexInputAttributeDescription):TpvInt32;
begin
 if length(aVertexInputAttributeDescriptions)>0 then begin
  result:=fCountVertexInputAttributeDescriptions;
  inc(fCountVertexInputAttributeDescriptions,length(aVertexInputAttributeDescriptions));
  if length(fVertexInputAttributeDescriptions)<fCountVertexInputAttributeDescriptions then begin
   SetLength(fVertexInputAttributeDescriptions,fCountVertexInputAttributeDescriptions*2);
  end;
  Move(aVertexInputAttributeDescriptions[0],fVertexInputAttributeDescriptions[result],length(aVertexInputAttributeDescriptions)*SizeOf(TVkVertexInputAttributeDescription));
 end else begin
  result:=-1;
 end;
end;

procedure TpvVulkanPipelineVertexInputState.Initialize;
begin
 SetLength(fVertexInputBindingDescriptions,fCountVertexInputBindingDescriptions);
 SetLength(fVertexInputAttributeDescriptions,fCountVertexInputAttributeDescriptions);
 if (fCountVertexInputBindingDescriptions>0) or (fCountVertexInputAttributeDescriptions>0) then begin
  fVertexInputStateCreateInfo.vertexBindingDescriptionCount:=fCountVertexInputBindingDescriptions;
  if fCountVertexInputBindingDescriptions>0 then begin
   fVertexInputStateCreateInfo.pVertexBindingDescriptions:=@fVertexInputBindingDescriptions[0];
  end;
  fVertexInputStateCreateInfo.vertexAttributeDescriptionCount:=fCountVertexInputAttributeDescriptions;
  if fCountVertexInputAttributeDescriptions>0 then begin
   fVertexInputStateCreateInfo.pVertexAttributeDescriptions:=@fVertexInputAttributeDescriptions[0];
  end;
 end;
end;

constructor TpvVulkanPipelineInputAssemblyState.Create;
begin
 inherited Create;

 FillChar(fInputAssemblyStateCreateInfo,SizeOf(TVkPipelineInputAssemblyStateCreateInfo),#0);
 fInputAssemblyStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
 fInputAssemblyStateCreateInfo.pNext:=nil;
 fInputAssemblyStateCreateInfo.flags:=0;
 fInputAssemblyStateCreateInfo.topology:=VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
 fInputAssemblyStateCreateInfo.primitiveRestartEnable:=VK_FALSE;

 fPointerToInputAssemblyStateCreateInfo:=@fInputAssemblyStateCreateInfo;

end;

destructor TpvVulkanPipelineInputAssemblyState.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanPipelineInputAssemblyState.Assign(const aFrom:TpvVulkanPipelineInputAssemblyState);
begin
 fInputAssemblyStateCreateInfo:=aFrom.fInputAssemblyStateCreateInfo;
end;

procedure TpvVulkanPipelineInputAssemblyState.SetInputAssemblyState(const aTopology:TVkPrimitiveTopology;const aPrimitiveRestartEnable:boolean);
begin
 fInputAssemblyStateCreateInfo.topology:=aTopology;
 fInputAssemblyStateCreateInfo.primitiveRestartEnable:=BooleanToVkBool[aPrimitiveRestartEnable];
end;

function TpvVulkanPipelineInputAssemblyState.GetTopology:TVkPrimitiveTopology;
begin
 result:=fInputAssemblyStateCreateInfo.topology;
end;

procedure TpvVulkanPipelineInputAssemblyState.SetTopology(const aNewValue:TVkPrimitiveTopology);
begin
 fInputAssemblyStateCreateInfo.topology:=aNewValue;
end;

function TpvVulkanPipelineInputAssemblyState.GetPrimitiveRestartEnable:boolean;
begin
 result:=fInputAssemblyStateCreateInfo.primitiveRestartEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineInputAssemblyState.SetPrimitiveRestartEnable(const aNewValue:boolean);
begin
 fInputAssemblyStateCreateInfo.primitiveRestartEnable:=BooleanToVkBool[aNewValue];
end;

constructor TpvVulkanPipelineTessellationState.Create;
begin
 inherited Create;

 FillChar(fTessellationStateCreateInfo,SizeOf(TVkPipelineTessellationStateCreateInfo),#0);
 fTessellationStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_TESSELLATION_STATE_CREATE_INFO;
 fTessellationStateCreateInfo.pNext:=nil;
 fTessellationStateCreateInfo.flags:=0;
 fTessellationStateCreateInfo.patchControlPoints:=0;

 fPointerToTessellationStateCreateInfo:=@fTessellationStateCreateInfo;

end;

destructor TpvVulkanPipelineTessellationState.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanPipelineTessellationState.Assign(const aFrom:TpvVulkanPipelineTessellationState);
begin
 fTessellationStateCreateInfo:=aFrom.fTessellationStateCreateInfo;
end;

function TpvVulkanPipelineTessellationState.GetPatchControlPoints:TpvUInt32;
begin
 result:=fTessellationStateCreateInfo.patchControlPoints;
end;

procedure TpvVulkanPipelineTessellationState.SetPatchControlPoints(const aNewValue:TpvUInt32);
begin
 fTessellationStateCreateInfo.patchControlPoints:=aNewValue;
end;

procedure TpvVulkanPipelineTessellationState.SetTessellationState(const aPatchControlPoints:TpvUInt32);
begin
 fTessellationStateCreateInfo.patchControlPoints:=aPatchControlPoints;
end;

constructor TpvVulkanPipelineViewPortState.Create;
begin

 inherited Create;

 FillChar(fViewportStateCreateInfo,SizeOf(TVkPipelineViewportStateCreateInfo),#0);
 fViewportStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
 fViewportStateCreateInfo.pNext:=nil;
 fViewportStateCreateInfo.flags:=0;
 fViewportStateCreateInfo.viewportCount:=0;
 fViewportStateCreateInfo.pViewports:=nil;
 fViewportStateCreateInfo.scissorCount:=0;
 fViewportStateCreateInfo.pScissors:=nil;

 fPointerToViewportStateCreateInfo:=@fViewportStateCreateInfo;

 fViewPorts:=nil;
 fCountViewPorts:=0;
 fDynamicViewPorts:=false;

 fScissors:=nil;
 fCountScissors:=0;
 fDynamicScissors:=false;

end;

destructor TpvVulkanPipelineViewPortState.Destroy;
begin
 SetLength(fViewPorts,0);
 SetLength(fScissors,0);
 inherited Destroy;
end;

procedure TpvVulkanPipelineViewPortState.Assign(const aFrom:TpvVulkanPipelineViewPortState);
begin
 fViewPorts:=copy(aFrom.fViewPorts);
 fCountViewPorts:=aFrom.fCountViewPorts;
 fScissors:=copy(aFrom.fScissors);
 fCountScissors:=aFrom.fCountScissors;
end;

function TpvVulkanPipelineViewPortState.GetViewPort(const aIndex:TpvInt32):PVkViewport;
begin
 result:=@fViewPorts[aIndex];
end;

function TpvVulkanPipelineViewPortState.GetScissor(const aIndex:TpvInt32):PVkRect2D;
begin
 result:=@fScissors[aIndex];
end;

procedure TpvVulkanPipelineViewPortState.SetCountViewPorts(const aNewCount:TpvInt32);
begin
 fCountViewPorts:=aNewCount;
 if length(fViewPorts)<fCountViewPorts then begin
  SetLength(fViewPorts,fCountViewPorts*2);
 end;
end;

procedure TpvVulkanPipelineViewPortState.SetCountScissors(const aNewCount:TpvInt32);
begin
 fCountScissors:=aNewCount;
 if length(fScissors)<fCountScissors then begin
  SetLength(fScissors,fCountScissors*2);
 end;
end;

function TpvVulkanPipelineViewPortState.AddViewPort(const aViewPort:TVkViewport):TpvInt32;
begin
 result:=fCountViewPorts;
 inc(fCountViewPorts);
 if length(fViewPorts)<fCountViewPorts then begin
  SetLength(fViewPorts,fCountViewPorts*2);
 end;
 fViewPorts[result]:=aViewPort;
end;

function TpvVulkanPipelineViewPortState.AddViewPort(const pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth:TpvFloat):TpvInt32;
var Viewport:PVkViewport;
begin
 result:=fCountViewPorts;
 inc(fCountViewPorts);
 if length(fViewPorts)<fCountViewPorts then begin
  SetLength(fViewPorts,fCountViewPorts*2);
 end;
 Viewport:=@fViewPorts[result];
 Viewport^.x:=pX;
 Viewport^.y:=pY;
 Viewport^.width:=aWidth;
 Viewport^.height:=aHeight;
 Viewport^.minDepth:=aMinDepth;
 Viewport^.maxDepth:=aMaxDepth;
end;

function TpvVulkanPipelineViewPortState.AddViewPorts(const aViewPorts:array of TVkViewport):TpvInt32;
begin
 if length(aViewPorts)>0 then begin
  result:=fCountViewPorts;
  inc(fCountViewPorts,length(aViewPorts));
  if length(fViewPorts)<fCountViewPorts then begin
   SetLength(fViewPorts,fCountViewPorts*2);
  end;
  Move(aViewPorts[0],fViewPorts[result],length(aViewPorts)*SizeOf(TVkViewport));
 end else begin
  result:=-1;
 end;
end;

function TpvVulkanPipelineViewPortState.AddScissor(const aScissor:TVkRect2D):TpvInt32;
begin
 result:=fCountScissors;
 inc(fCountScissors);
 if length(fScissors)<fCountScissors then begin
  SetLength(fScissors,fCountScissors*2);
 end;
 fScissors[result]:=aScissor;
end;

function TpvVulkanPipelineViewPortState.AddScissor(const pX,pY:TpvInt32;const aWidth,aHeight:TpvUInt32):TpvInt32;
var Scissor:PVkRect2D;
begin
 result:=fCountScissors;
 inc(fCountScissors);
 if length(fScissors)<fCountScissors then begin
  SetLength(fScissors,fCountScissors*2);
 end;
 Scissor:=@fScissors[result];
 Scissor^.offset.x:=pX;
 Scissor^.offset.y:=pY;
 Scissor^.extent.width:=aWidth;
 Scissor^.extent.height:=aHeight;
end;

function TpvVulkanPipelineViewPortState.AddScissors(const aScissors:array of TVkRect2D):TpvInt32;
begin
 if length(aScissors)>0 then begin
  result:=fCountScissors;
  inc(fCountScissors,length(aScissors));
  if length(fScissors)<fCountScissors then begin
   SetLength(fScissors,fCountScissors*2);
  end;
  Move(aScissors[0],fScissors[result],length(aScissors)*SizeOf(TVkRect2D));
 end else begin
  result:=-1;
 end;
end;

procedure TpvVulkanPipelineViewPortState.Initialize;
begin
 SetLength(fViewPorts,fCountViewPorts);
 SetLength(fScissors,fCountScissors);
 if (fCountViewPorts>0) or (fCountScissors>0) then begin
  fViewportStateCreateInfo.viewportCount:=fCountViewPorts;
  if (fCountViewPorts>0) and not fDynamicViewPorts then begin
   fViewportStateCreateInfo.pViewports:=@fViewPorts[0];
  end else begin
   fViewportStateCreateInfo.pViewports:=nil;
  end;
  fViewportStateCreateInfo.scissorCount:=fCountScissors;
  if (fCountScissors>0) and not fDynamicScissors then begin
   fViewportStateCreateInfo.pScissors:=@fScissors[0];
  end else begin
   fViewportStateCreateInfo.pScissors:=nil;
  end;
 end;
end;

constructor TpvVulkanPipelineRasterizationState.Create;
begin

 inherited Create;

 FillChar(fRasterizationStateCreateInfo,SizeOf(TVkPipelineRasterizationStateCreateInfo),#0);
 fRasterizationStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
 fRasterizationStateCreateInfo.pNext:=nil;
 fRasterizationStateCreateInfo.flags:=0;
 fRasterizationStateCreateInfo.depthClampEnable:=VK_TRUE;
 fRasterizationStateCreateInfo.rasterizerDiscardEnable:=VK_FALSE;
 fRasterizationStateCreateInfo.polygonMode:=VK_POLYGON_MODE_FILL;
 fRasterizationStateCreateInfo.cullMode:=TVkCullModeFlags(VK_CULL_MODE_NONE);
 fRasterizationStateCreateInfo.frontFace:=VK_FRONT_FACE_COUNTER_CLOCKWISE;
 fRasterizationStateCreateInfo.depthBiasEnable:=VK_TRUE;
 fRasterizationStateCreateInfo.depthBiasConstantFactor:=0.0;
 fRasterizationStateCreateInfo.depthBiasClamp:=0.0;
 fRasterizationStateCreateInfo.depthBiasSlopeFactor:=0.0;
 fRasterizationStateCreateInfo.lineWidth:=1.0;

 fPointerToRasterizationStateCreateInfo:=@fRasterizationStateCreateInfo;

end;

destructor TpvVulkanPipelineRasterizationState.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanPipelineRasterizationState.Assign(const aFrom:TpvVulkanPipelineRasterizationState);
begin
 fRasterizationStateCreateInfo:=aFrom.fRasterizationStateCreateInfo;
end;

function TpvVulkanPipelineRasterizationState.GetDepthClampEnable:boolean;
begin
 result:=fRasterizationStateCreateInfo.depthClampEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineRasterizationState.SetDepthClampEnable(const aNewValue:boolean);
begin
 fRasterizationStateCreateInfo.depthClampEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineRasterizationState.GetRasterizerDiscardEnable:boolean;
begin
 result:=fRasterizationStateCreateInfo.rasterizerDiscardEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineRasterizationState.SetRasterizerDiscardEnable(const aNewValue:boolean);
begin
 fRasterizationStateCreateInfo.rasterizerDiscardEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineRasterizationState.GetPolygonMode:TVkPolygonMode;
begin
 result:=fRasterizationStateCreateInfo.polygonMode;
end;

procedure TpvVulkanPipelineRasterizationState.SetPolygonMode(const aNewValue:TVkPolygonMode);
begin
 fRasterizationStateCreateInfo.polygonMode:=aNewValue;
end;

function TpvVulkanPipelineRasterizationState.GetCullMode:TVkCullModeFlags;
begin
 result:=fRasterizationStateCreateInfo.cullMode;
end;

procedure TpvVulkanPipelineRasterizationState.SetCullMode(const aNewValue:TVkCullModeFlags);
begin
 fRasterizationStateCreateInfo.cullMode:=aNewValue;
end;

function TpvVulkanPipelineRasterizationState.GetFrontFace:TVkFrontFace;
begin
 result:=fRasterizationStateCreateInfo.frontFace;
end;

procedure TpvVulkanPipelineRasterizationState.SetFrontFace(const aNewValue:TVkFrontFace);
begin
 fRasterizationStateCreateInfo.frontFace:=aNewValue;
end;

function TpvVulkanPipelineRasterizationState.GetDepthBiasEnable:boolean;
begin
 result:=fRasterizationStateCreateInfo.depthBiasEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineRasterizationState.SetDepthBiasEnable(const aNewValue:boolean);
begin
 fRasterizationStateCreateInfo.depthBiasEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineRasterizationState.GetDepthBiasConstantFactor:TpvFloat;
begin
 result:=fRasterizationStateCreateInfo.depthBiasConstantFactor;
end;

procedure TpvVulkanPipelineRasterizationState.SetDepthBiasConstantFactor(const aNewValue:TpvFloat);
begin
 fRasterizationStateCreateInfo.depthBiasConstantFactor:=aNewValue;
end;

function TpvVulkanPipelineRasterizationState.GetDepthBiasClamp:TpvFloat;
begin
 result:=fRasterizationStateCreateInfo.depthBiasClamp;
end;

procedure TpvVulkanPipelineRasterizationState.SetDepthBiasClamp(const aNewValue:TpvFloat);
begin
 fRasterizationStateCreateInfo.depthBiasClamp:=aNewValue;
end;

function TpvVulkanPipelineRasterizationState.GetDepthBiasSlopeFactor:TpvFloat;
begin
 result:=fRasterizationStateCreateInfo.depthBiasSlopeFactor;
end;

procedure TpvVulkanPipelineRasterizationState.SetDepthBiasSlopeFactor(const aNewValue:TpvFloat);
begin
 fRasterizationStateCreateInfo.depthBiasSlopeFactor:=aNewValue;
end;

function TpvVulkanPipelineRasterizationState.GetLineWidth:TpvFloat;
begin
 result:=fRasterizationStateCreateInfo.lineWidth;
end;

procedure TpvVulkanPipelineRasterizationState.SetLineWidth(const aNewValue:TpvFloat);
begin
 fRasterizationStateCreateInfo.lineWidth:=aNewValue;
end;

procedure TpvVulkanPipelineRasterizationState.SetRasterizationState(const aDepthClampEnable:boolean;
                                                                    const aRasterizerDiscardEnable:boolean;
                                                                    const aPolygonMode:TVkPolygonMode;
                                                                    const aCullMode:TVkCullModeFlags;
                                                                    const aFrontFace:TVkFrontFace;
                                                                    const aDepthBiasEnable:boolean;
                                                                    const aDepthBiasConstantFactor:TpvFloat;
                                                                    const aDepthBiasClamp:TpvFloat;
                                                                    const aDepthBiasSlopeFactor:TpvFloat;
                                                                    const aLineWidth:TpvFloat);
begin
 fRasterizationStateCreateInfo.depthClampEnable:=BooleanToVkBool[aDepthClampEnable];
 fRasterizationStateCreateInfo.rasterizerDiscardEnable:=BooleanToVkBool[aRasterizerDiscardEnable];
 fRasterizationStateCreateInfo.polygonMode:=aPolygonMode;
 fRasterizationStateCreateInfo.cullMode:=aCullMode;
 fRasterizationStateCreateInfo.frontFace:=aFrontFace;
 fRasterizationStateCreateInfo.depthBiasEnable:=BooleanToVkBool[aDepthBiasEnable];
 fRasterizationStateCreateInfo.depthBiasConstantFactor:=aDepthBiasConstantFactor;
 fRasterizationStateCreateInfo.depthBiasClamp:=aDepthBiasClamp;
 fRasterizationStateCreateInfo.depthBiasSlopeFactor:=aDepthBiasSlopeFactor;
 fRasterizationStateCreateInfo.lineWidth:=aLineWidth;
end;

constructor TpvVulkanPipelineMultisampleState.Create;
begin

 inherited Create;

 FillChar(fMultisampleStateCreateInfo,SizeOf(TVkPipelineMultisampleStateCreateInfo),#0);
 fMultisampleStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
 fMultisampleStateCreateInfo.pNext:=nil;
 fMultisampleStateCreateInfo.flags:=0;
 fMultisampleStateCreateInfo.rasterizationSamples:=VK_SAMPLE_COUNT_1_BIT;
 fMultisampleStateCreateInfo.sampleShadingEnable:=VK_FALSE;
 fMultisampleStateCreateInfo.minSampleShading:=1.0;
 fMultisampleStateCreateInfo.pSampleMask:=nil;
 fMultisampleStateCreateInfo.alphaToCoverageEnable:=VK_FALSE;
 fMultisampleStateCreateInfo.alphaToOneEnable:=VK_FALSE;

 fPointerToMultisampleStateCreateInfo:=@fMultisampleStateCreateInfo;

 fSampleMasks:=nil;
 fCountSampleMasks:=0;

end;

destructor TpvVulkanPipelineMultisampleState.Destroy;
begin
 SetLength(fSampleMasks,0);
 inherited Destroy;
end;

procedure TpvVulkanPipelineMultisampleState.Assign(const aFrom:TpvVulkanPipelineMultisampleState);
begin
 fMultisampleStateCreateInfo:=aFrom.fMultisampleStateCreateInfo;
 fMultisampleStateCreateInfo.pSampleMask:=nil;
 fSampleMasks:=copy(aFrom.fSampleMasks);
 fCountSampleMasks:=aFrom.fCountSampleMasks;
end;

function TpvVulkanPipelineMultisampleState.AddSampleMask(const aSampleMask:TVkSampleMask):TpvInt32;
begin
 result:=fCountSampleMasks;
 inc(fCountSampleMasks);
 if length(fSampleMasks)<fCountSampleMasks then begin
  SetLength(fSampleMasks,fCountSampleMasks*2);
 end;
 fSampleMasks[result]:=aSampleMask;
end;

function TpvVulkanPipelineMultisampleState.AddSampleMasks(const aSampleMasks:array of TVkSampleMask):TpvInt32;
begin
 if length(aSampleMasks)>0 then begin
  result:=fCountSampleMasks;
  inc(fCountSampleMasks,length(aSampleMasks));
  if length(fSampleMasks)<fCountSampleMasks then begin
   SetLength(fSampleMasks,fCountSampleMasks*2);
  end;
  Move(aSampleMasks[0],fSampleMasks[result],length(aSampleMasks)*SizeOf(TVkSampleMask));
 end else begin
  result:=-1;
 end;
end;

function TpvVulkanPipelineMultisampleState.GetRasterizationSamples:TVkSampleCountFlagBits;
begin
 result:=fMultisampleStateCreateInfo.rasterizationSamples;
end;

procedure TpvVulkanPipelineMultisampleState.SetRasterizationSamples(const aNewValue:TVkSampleCountFlagBits);
begin
 fMultisampleStateCreateInfo.rasterizationSamples:=aNewValue;
end;

function TpvVulkanPipelineMultisampleState.GetSampleShadingEnable:boolean;
begin
 result:=fMultisampleStateCreateInfo.sampleShadingEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineMultisampleState.SetSampleShadingEnable(const aNewValue:boolean);
begin
 fMultisampleStateCreateInfo.sampleShadingEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineMultisampleState.GetSampleMask(const aIndex:TpvInt32):TVkSampleMask;
begin
 result:=fSampleMasks[aIndex];
end;

procedure TpvVulkanPipelineMultisampleState.SetSampleMask(const aIndex:TpvInt32;const aNewValue:TVkSampleMask);
begin
 fSampleMasks[aIndex]:=aNewValue;                                                          
end;

procedure TpvVulkanPipelineMultisampleState.SetCountSampleMasks(const aNewCount:TpvInt32);
begin
 fCountSampleMasks:=aNewCount;
 if length(fSampleMasks)<fCountSampleMasks then begin
  SetLength(fSampleMasks,fCountSampleMasks*2);
 end;
end;

function TpvVulkanPipelineMultisampleState.GetMinSampleShading:TpvFloat;
begin
 result:=fMultisampleStateCreateInfo.minSampleShading;
end;

procedure TpvVulkanPipelineMultisampleState.SetMinSampleShading(const aNewValue:TpvFloat);
begin
 fMultisampleStateCreateInfo.minSampleShading:=aNewValue;
end;

function TpvVulkanPipelineMultisampleState.GetAlphaToCoverageEnable:boolean;
begin
 result:=fMultisampleStateCreateInfo.alphaToCoverageEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineMultisampleState.SetAlphaToCoverageEnable(const aNewValue:boolean);
begin
 fMultisampleStateCreateInfo.alphaToCoverageEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineMultisampleState.GetAlphaToOneEnable:boolean;
begin
 result:=fMultisampleStateCreateInfo.alphaToOneEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineMultisampleState.SetAlphaToOneEnable(const aNewValue:boolean);
begin
 fMultisampleStateCreateInfo.alphaToOneEnable:=BooleanToVkBool[aNewValue];
end;

procedure TpvVulkanPipelineMultisampleState.SetMultisampleState(const aRasterizationSamples:TVkSampleCountFlagBits;
                                                                const aSampleShadingEnable:boolean;
                                                                const aMinSampleShading:TpvFloat;
                                                                const aSampleMask:array of TVkSampleMask;
                                                                const aAlphaToCoverageEnable:boolean;
                                                                const aAlphaToOneEnable:boolean);
begin
 fMultisampleStateCreateInfo.rasterizationSamples:=aRasterizationSamples;
 fMultisampleStateCreateInfo.sampleShadingEnable:=BooleanToVkBool[aSampleShadingEnable];
 fMultisampleStateCreateInfo.minSampleShading:=aMinSampleShading;
 fCountSampleMasks:=length(aSampleMask);
 SetLength(fSampleMasks,fCountSampleMasks);
 if length(aSampleMask)>0 then begin
  Move(aSampleMask[0],fSampleMasks[0],length(aSampleMask)*SizeOf(TVkSampleMask));
 end;
 fMultisampleStateCreateInfo.alphaToCoverageEnable:=BooleanToVkBool[aAlphaToCoverageEnable];
 fMultisampleStateCreateInfo.alphaToOneEnable:=BooleanToVkBool[aAlphaToOneEnable];
end;

procedure TpvVulkanPipelineMultisampleState.Initialize;
begin
 if fCountSampleMasks>0 then begin
  SetLength(fSampleMasks,fCountSampleMasks);
  fMultisampleStateCreateInfo.pSampleMask:=@fSampleMasks[0];
 end else begin
  fMultisampleStateCreateInfo.pSampleMask:=nil;
 end;
end;

constructor TpvVulkanStencilOpState.Create(const aStencilOpState:PVkStencilOpState);
begin
 inherited Create;
 fStencilOpState:=aStencilOpState;
end;

destructor TpvVulkanStencilOpState.Destroy;
begin
 inherited Destroy;
end;

procedure TpvVulkanStencilOpState.Assign(const aFrom:TpvVulkanStencilOpState);
begin
 fStencilOpState^:=aFrom.fStencilOpState^;
end;

function TpvVulkanStencilOpState.GetFailOp:TVkStencilOp;
begin
 result:=fStencilOpState^.failOp;
end;

procedure TpvVulkanStencilOpState.SetFailOp(const aNewValue:TVkStencilOp);
begin
 fStencilOpState^.failOp:=aNewValue;
end;

function TpvVulkanStencilOpState.GetPassOp:TVkStencilOp;
begin
 result:=fStencilOpState^.passOp;
end;

procedure TpvVulkanStencilOpState.SetPassOp(const aNewValue:TVkStencilOp);
begin
 fStencilOpState^.passOp:=aNewValue;
end;

function TpvVulkanStencilOpState.GetDepthFailOp:TVkStencilOp;
begin
 result:=fStencilOpState^.depthFailOp;
end;

procedure TpvVulkanStencilOpState.SetDepthFailOp(const aNewValue:TVkStencilOp);
begin
 fStencilOpState^.depthFailOp:=aNewValue;
end;

function TpvVulkanStencilOpState.GetCompareOp:TVkCompareOp;
begin
 result:=fStencilOpState^.compareOp;
end;

procedure TpvVulkanStencilOpState.SetCompareOp(const aNewValue:TVkCompareOp);
begin
 fStencilOpState^.compareOp:=aNewValue;
end;

function TpvVulkanStencilOpState.GetCompareMask:TpvUInt32;
begin
 result:=fStencilOpState^.compareMask;
end;

procedure TpvVulkanStencilOpState.SetCompareMask(const aNewValue:TpvUInt32);
begin
 fStencilOpState^.compareMask:=aNewValue;
end;

function TpvVulkanStencilOpState.GetWriteMask:TpvUInt32;
begin
 result:=fStencilOpState^.writeMask;
end;

procedure TpvVulkanStencilOpState.SetWriteMask(const aNewValue:TpvUInt32);
begin
 fStencilOpState^.writeMask:=aNewValue;
end;

function TpvVulkanStencilOpState.GetReference:TpvUInt32;
begin
 result:=fStencilOpState^.reference;
end;

procedure TpvVulkanStencilOpState.SetReference(const aNewValue:TpvUInt32);
begin
 fStencilOpState^.reference:=aNewValue;
end;

constructor TpvVulkanPipelineDepthStencilState.Create;
begin

 inherited Create;

 FillChar(fDepthStencilStateCreateInfo,SizeOf(TVkPipelineDepthStencilStateCreateInfo),#0);
 fDepthStencilStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
 fDepthStencilStateCreateInfo.pNext:=nil;
 fDepthStencilStateCreateInfo.flags:=0;      
 fDepthStencilStateCreateInfo.depthTestEnable:=VK_TRUE;
 fDepthStencilStateCreateInfo.depthWriteEnable:=VK_TRUE;
 fDepthStencilStateCreateInfo.depthCompareOp:=VK_COMPARE_OP_LESS_OR_EQUAL;
 fDepthStencilStateCreateInfo.depthBoundsTestEnable:=VK_FALSE;
 fDepthStencilStateCreateInfo.stencilTestEnable:=VK_FALSE;
 fDepthStencilStateCreateInfo.front.failOp:=VK_STENCIL_OP_KEEP;
 fDepthStencilStateCreateInfo.front.depthFailOp:=VK_STENCIL_OP_KEEP;
 fDepthStencilStateCreateInfo.front.compareOp:=VK_COMPARE_OP_ALWAYS;
 fDepthStencilStateCreateInfo.front.compareMask:=0;
 fDepthStencilStateCreateInfo.front.writeMask:=0;
 fDepthStencilStateCreateInfo.front.reference:=0;
 fDepthStencilStateCreateInfo.back.failOp:=VK_STENCIL_OP_KEEP;
 fDepthStencilStateCreateInfo.back.depthFailOp:=VK_STENCIL_OP_KEEP;
 fDepthStencilStateCreateInfo.back.compareOp:=VK_COMPARE_OP_ALWAYS;
 fDepthStencilStateCreateInfo.back.compareMask:=0;
 fDepthStencilStateCreateInfo.back.writeMask:=0;
 fDepthStencilStateCreateInfo.back.reference:=0;
 fDepthStencilStateCreateInfo.minDepthBounds:=0.0;
 fDepthStencilStateCreateInfo.maxDepthBounds:=1.0;

 fPointerToDepthStencilStateCreateInfo:=@fDepthStencilStateCreateInfo;

 fFrontStencilOpState:=TpvVulkanStencilOpState.Create(@fDepthStencilStateCreateInfo.front);

 fBackStencilOpState:=TpvVulkanStencilOpState.Create(@fDepthStencilStateCreateInfo.back);

end;

destructor TpvVulkanPipelineDepthStencilState.Destroy;
begin
 fFrontStencilOpState.Free;
 fBackStencilOpState.Free;
 inherited Destroy;
end;

procedure TpvVulkanPipelineDepthStencilState.Assign(const aFrom:TpvVulkanPipelineDepthStencilState);
begin
 fDepthStencilStateCreateInfo:=aFrom.fDepthStencilStateCreateInfo;
end;

function TpvVulkanPipelineDepthStencilState.GetDepthTestEnable:boolean;
begin
 result:=fDepthStencilStateCreateInfo.depthTestEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineDepthStencilState.SetDepthTestEnable(const aNewValue:boolean);
begin
 fDepthStencilStateCreateInfo.depthTestEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineDepthStencilState.GetDepthWriteEnable:boolean;
begin
 result:=fDepthStencilStateCreateInfo.depthWriteEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineDepthStencilState.SetDepthWriteEnable(const aNewValue:boolean);
begin
 fDepthStencilStateCreateInfo.depthWriteEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineDepthStencilState.GetDepthCompareOp:TVkCompareOp;
begin
 result:=fDepthStencilStateCreateInfo.depthCompareOp;
end;

procedure TpvVulkanPipelineDepthStencilState.SetDepthCompareOp(const aNewValue:TVkCompareOp);
begin
 fDepthStencilStateCreateInfo.depthCompareOp:=aNewValue;
end;

function TpvVulkanPipelineDepthStencilState.GetDepthBoundsTestEnable:boolean;
begin
 result:=fDepthStencilStateCreateInfo.depthBoundsTestEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineDepthStencilState.SetDepthBoundsTestEnable(const aNewValue:boolean);
begin
 fDepthStencilStateCreateInfo.depthBoundsTestEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineDepthStencilState.GetStencilTestEnable:boolean;
begin
 result:=fDepthStencilStateCreateInfo.stencilTestEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineDepthStencilState.SetStencilTestEnable(const aNewValue:boolean);
begin
 fDepthStencilStateCreateInfo.stencilTestEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineDepthStencilState.GetMinDepthBounds:TpvFloat;
begin
 result:=fDepthStencilStateCreateInfo.minDepthBounds;
end;

procedure TpvVulkanPipelineDepthStencilState.SetMinDepthBounds(const aNewValue:TpvFloat);
begin
 fDepthStencilStateCreateInfo.minDepthBounds:=aNewValue;
end;

function TpvVulkanPipelineDepthStencilState.GetMaxDepthBounds:TpvFloat;
begin
 result:=fDepthStencilStateCreateInfo.maxDepthBounds;
end;

procedure TpvVulkanPipelineDepthStencilState.SetMaxDepthBounds(const aNewValue:TpvFloat);
begin
 fDepthStencilStateCreateInfo.maxDepthBounds:=aNewValue;
end;

procedure TpvVulkanPipelineDepthStencilState.SetDepthStencilState(const aDepthTestEnable:boolean;
                                                                  const aDepthWriteEnable:boolean;
                                                                  const aDepthCompareOp:TVkCompareOp;
                                                                  const aDepthBoundsTestEnable:boolean;
                                                                  const aStencilTestEnable:boolean;
                                                                  const aFront:TVkStencilOpState;
                                                                  const aBack:TVkStencilOpState;
                                                                  const aMinDepthBounds:TpvFloat;
                                                                  const aMaxDepthBounds:TpvFloat);
begin
 fDepthStencilStateCreateInfo.depthTestEnable:=BooleanToVkBool[aDepthTestEnable];
 fDepthStencilStateCreateInfo.depthWriteEnable:=BooleanToVkBool[aDepthWriteEnable];
 fDepthStencilStateCreateInfo.depthCompareOp:=aDepthCompareOp;
 fDepthStencilStateCreateInfo.depthBoundsTestEnable:=BooleanToVkBool[aDepthBoundsTestEnable];
 fDepthStencilStateCreateInfo.stencilTestEnable:=BooleanToVkBool[aStencilTestEnable];
 fDepthStencilStateCreateInfo.front:=aFront;
 fDepthStencilStateCreateInfo.back:=aBack;
 fDepthStencilStateCreateInfo.minDepthBounds:=aMinDepthBounds;
 fDepthStencilStateCreateInfo.maxDepthBounds:=aMaxDepthBounds;
end;

constructor TpvVulkanPipelineColorBlendState.Create;
begin

 inherited Create;

 FillChar(fColorBlendStateCreateInfo,SizeOf(TVkPipelineColorBlendStateCreateInfo),#0);
 fColorBlendStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
 fColorBlendStateCreateInfo.pNext:=nil;
 fColorBlendStateCreateInfo.flags:=0;
 fColorBlendStateCreateInfo.logicOpEnable:=VK_FALSE;
 fColorBlendStateCreateInfo.logicOp:=VK_LOGIC_OP_NO_OP;
 fColorBlendStateCreateInfo.blendConstants[0]:=0.0;
 fColorBlendStateCreateInfo.blendConstants[1]:=0.0;
 fColorBlendStateCreateInfo.blendConstants[2]:=0.0;
 fColorBlendStateCreateInfo.blendConstants[3]:=0.0;

 fPointerToColorBlendStateCreateInfo:=@fColorBlendStateCreateInfo;

 fColorBlendAttachmentStates:=nil;
 fCountColorBlendAttachmentStates:=0;

end;

destructor TpvVulkanPipelineColorBlendState.Destroy;
begin
 SetLength(fColorBlendAttachmentStates,0);
 inherited Destroy;
end;

procedure TpvVulkanPipelineColorBlendState.Assign(const aFrom:TpvVulkanPipelineColorBlendState);
begin
 fColorBlendStateCreateInfo:=aFrom.fColorBlendStateCreateInfo;
 fColorBlendStateCreateInfo.attachmentCount:=0;
 fColorBlendStateCreateInfo.pAttachments:=nil;
end;

function TpvVulkanPipelineColorBlendState.GetLogicOpEnable:boolean;
begin
 result:=fColorBlendStateCreateInfo.logicOpEnable<>VK_FALSE;
end;

procedure TpvVulkanPipelineColorBlendState.SetLogicOpEnable(const aNewValue:boolean);
begin
 fColorBlendStateCreateInfo.logicOpEnable:=BooleanToVkBool[aNewValue];
end;

function TpvVulkanPipelineColorBlendState.GetLogicOp:TVkLogicOp;
begin
 result:=fColorBlendStateCreateInfo.logicOp;
end;

procedure TpvVulkanPipelineColorBlendState.SetLogicOp(const aNewValue:TVkLogicOp);
begin
 fColorBlendStateCreateInfo.logicOp:=aNewValue;
end;

procedure TpvVulkanPipelineColorBlendState.SetCountColorBlendAttachmentStates(const aNewCount:TpvInt32);
begin
 fCountColorBlendAttachmentStates:=aNewCount;
 if length(fColorBlendAttachmentStates)<fCountColorBlendAttachmentStates then begin
  SetLength(fColorBlendAttachmentStates,fCountColorBlendAttachmentStates*2);
 end;
end;

function TpvVulkanPipelineColorBlendState.GetColorBlendAttachmentState(const aIndex:TpvInt32):PVkPipelineColorBlendAttachmentState;
begin
 result:=@fColorBlendAttachmentStates[aIndex];
end;

function TpvVulkanPipelineColorBlendState.GetBlendConstant(const aIndex:TpvInt32):TpvFloat;
begin
 result:=fColorBlendStateCreateInfo.blendConstants[aIndex];
end;

procedure TpvVulkanPipelineColorBlendState.SetBlendConstant(const aIndex:TpvInt32;const aNewValue:TpvFloat);
begin
 fColorBlendStateCreateInfo.blendConstants[aIndex]:=aNewValue;
end;

procedure TpvVulkanPipelineColorBlendState.SetColorBlendState(const aLogicOpEnable:boolean;
                                                              const aLogicOp:TVkLogicOp;
                                                              const aBlendConstants:array of TpvFloat);
var ArrayItemCount:TpvInt32;
begin
 fColorBlendStateCreateInfo.logicOpEnable:=BooleanToVkBool[aLogicOpEnable];
 fColorBlendStateCreateInfo.logicOp:=aLogicOp;
 ArrayItemCount:=length(aBlendConstants);
 if ArrayItemCount>length(fColorBlendStateCreateInfo.blendConstants) then begin
  ArrayItemCount:=length(fColorBlendStateCreateInfo.blendConstants);
 end;
 if ArrayItemCount>0 then begin
  Move(aBlendConstants[0],fColorBlendStateCreateInfo.blendConstants[0],ArrayItemCount*SizeOf(TpvFloat));
 end;
end;

function TpvVulkanPipelineColorBlendState.AddColorBlendAttachmentState(const aColorBlendAttachmentState:TVkPipelineColorBlendAttachmentState):TpvInt32;
begin
 result:=fCountColorBlendAttachmentStates;
 inc(fCountColorBlendAttachmentStates);
 if length(fColorBlendAttachmentStates)<fCountColorBlendAttachmentStates then begin
  SetLength(fColorBlendAttachmentStates,fCountColorBlendAttachmentStates*2);
 end;
 fColorBlendAttachmentStates[result]:=aColorBlendAttachmentState;
end;

function TpvVulkanPipelineColorBlendState.AddColorBlendAttachmentState(const aBlendEnable:boolean;
                                                                       const aSrcColorBlendFactor:TVkBlendFactor;
                                                                       const aDstColorBlendFactor:TVkBlendFactor;
                                                                       const aColorBlendOp:TVkBlendOp;
                                                                       const aSrcAlphaBlendFactor:TVkBlendFactor;
                                                                       const aDstAlphaBlendFactor:TVkBlendFactor;
                                                                       const aAlphaBlendOp:TVkBlendOp;
                                                                       const aColorWriteMask:TVkColorComponentFlags):TpvInt32;
var ColorBlendAttachmentState:PVkPipelineColorBlendAttachmentState;
begin
 result:=fCountColorBlendAttachmentStates;
 inc(fCountColorBlendAttachmentStates);
 if length(fColorBlendAttachmentStates)<fCountColorBlendAttachmentStates then begin
  SetLength(fColorBlendAttachmentStates,fCountColorBlendAttachmentStates*2);
 end;
 ColorBlendAttachmentState:=@fColorBlendAttachmentStates[result];
 if aBlendEnable then begin
  ColorBlendAttachmentState^.blendEnable:=VK_TRUE;
 end else begin
  ColorBlendAttachmentState^.blendEnable:=VK_FALSE;
 end;
 ColorBlendAttachmentState^.srcColorBlendFactor:=aSrcColorBlendFactor;
 ColorBlendAttachmentState^.dstColorBlendFactor:=aDstColorBlendFactor;
 ColorBlendAttachmentState^.colorBlendOp:=aColorBlendOp;
 ColorBlendAttachmentState^.srcAlphaBlendFactor:=aSrcAlphaBlendFactor;
 ColorBlendAttachmentState^.dstAlphaBlendFactor:=aDstAlphaBlendFactor;
 ColorBlendAttachmentState^.alphaBlendOp:=aAlphaBlendOp;
 ColorBlendAttachmentState^.colorWriteMask:=aColorWriteMask;
end;

function TpvVulkanPipelineColorBlendState.AddColorBlendAttachmentStates(const aColorBlendAttachmentStates:array of TVkPipelineColorBlendAttachmentState):TpvInt32;
begin
 if length(aColorBlendAttachmentStates)>0 then begin
  result:=fCountColorBlendAttachmentStates;
  inc(fCountColorBlendAttachmentStates,length(aColorBlendAttachmentStates));
  if length(fColorBlendAttachmentStates)<fCountColorBlendAttachmentStates then begin
   SetLength(fColorBlendAttachmentStates,fCountColorBlendAttachmentStates*2);
  end;
  Move(aColorBlendAttachmentStates[0],fColorBlendAttachmentStates[result],length(aColorBlendAttachmentStates)*SizeOf(TVkRect2D));
 end else begin
  result:=-1;
 end;
end;

procedure TpvVulkanPipelineColorBlendState.Initialize;
begin
 SetLength(fColorBlendAttachmentStates,fCountColorBlendAttachmentStates);
 if fCountColorBlendAttachmentStates>0 then begin
  fColorBlendStateCreateInfo.attachmentCount:=fCountColorBlendAttachmentStates;
  fColorBlendStateCreateInfo.pAttachments:=@fColorBlendAttachmentStates[0];
 end;
end;

constructor TpvVulkanPipelineDynamicState.Create;
begin

 inherited Create;

 FillChar(fDynamicStateCreateInfo,SizeOf(TVkPipelineDynamicStateCreateInfo),#0);
 fDynamicStateCreateInfo.sType:=VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO;
 fDynamicStateCreateInfo.pNext:=nil;
 fDynamicStateCreateInfo.flags:=0;
 fDynamicStateCreateInfo.dynamicStateCount:=0;
 fDynamicStateCreateInfo.pDynamicStates:=nil;

 fPointerToDynamicStateCreateInfo:=@fDynamicStateCreateInfo;

 fDynamicStates:=nil;
 fCountDynamicStates:=0;

end;

destructor TpvVulkanPipelineDynamicState.Destroy;
begin
 SetLength(fDynamicStates,0);
 inherited Destroy;
end;

procedure TpvVulkanPipelineDynamicState.Assign(const aFrom:TpvVulkanPipelineDynamicState);
begin
 fDynamicStates:=copy(aFrom.fDynamicStates);
 fCountDynamicStates:=aFrom.fCountDynamicStates;
end;

function TpvVulkanPipelineDynamicState.GetDynamicState(const aIndex:TpvInt32):PVkDynamicState;
begin
 result:=@fDynamicStates[aIndex];
end;

procedure TpvVulkanPipelineDynamicState.SetCountDynamicStates(const aNewCount:TpvInt32);
begin
 fCountDynamicStates:=aNewCount;
 if length(fDynamicStates)<fCountDynamicStates then begin
  SetLength(fDynamicStates,fCountDynamicStates*2);
 end;
end;

function TpvVulkanPipelineDynamicState.AddDynamicState(const aDynamicState:TVkDynamicState):TpvInt32;
begin
 result:=fCountDynamicStates;
 inc(fCountDynamicStates);
 if length(fDynamicStates)<fCountDynamicStates then begin
  SetLength(fDynamicStates,fCountDynamicStates*2);
 end;
 fDynamicStates[result]:=aDynamicState;
end;

function TpvVulkanPipelineDynamicState.AddDynamicStates(const aDynamicStates:array of TVkDynamicState):TpvInt32;
begin
 if length(aDynamicStates)>0 then begin
  result:=fCountDynamicStates;
  inc(fCountDynamicStates,length(aDynamicStates));
  if length(fDynamicStates)<fCountDynamicStates then begin
   SetLength(fDynamicStates,fCountDynamicStates*2);
  end;
  Move(aDynamicStates[0],fDynamicStates[result],length(aDynamicStates)*SizeOf(TVkDynamicState));
 end else begin
  result:=-1;
 end;
end;

procedure TpvVulkanPipelineDynamicState.Initialize;
begin
 SetLength(fDynamicStates,fCountDynamicStates);
 fDynamicStateCreateInfo.DynamicStateCount:=fCountDynamicStates;
 if fCountDynamicStates>0 then begin
  fDynamicStateCreateInfo.pDynamicStates:=@fDynamicStates[0];
 end;
end;

constructor TpvVulkanGraphicsPipelineConstructor.Create(const aDevice:TpvVulkanDevice;
                                                        const aCache:TpvVulkanPipelineCache;
                                                        const aFlags:TVkPipelineCreateFlags;
                                                        const aStages:array of TpvVulkanPipelineShaderStage;
                                                        const aLayout:TpvVulkanPipelineLayout;
                                                        const aRenderPass:TpvVulkanRenderPass;
                                                        const aSubPass:TpvUInt32;
                                                        const aBasePipelineHandle:TpvVulkanPipeline;
                                                        const aBasePipelineIndex:TpvInt32);
var Index:TpvInt32;
begin
 fStages:=nil;
 fCountStages:=0;

 inherited Create(aDevice);

 fVertexInputState:=TpvVulkanPipelineVertexInputState.Create;

 fInputAssemblyState:=TpvVulkanPipelineInputAssemblyState.Create;

 fTessellationState:=TpvVulkanPipelineTessellationState.Create;

 fViewPortState:=TpvVulkanPipelineViewPortState.Create;

 fRasterizationState:=TpvVulkanPipelineRasterizationState.Create;

 fMultisampleState:=TpvVulkanPipelineMultisampleState.Create;

 fDepthStencilState:=TpvVulkanPipelineDepthStencilState.Create;

 fColorBlendState:=TpvVulkanPipelineColorBlendState.Create;

 fDynamicState:=TpvVulkanPipelineDynamicState.Create;

 FillChar(fGraphicsPipelineCreateInfo,SizeOf(TVkGraphicsPipelineCreateInfo),#0);
 fGraphicsPipelineCreateInfo.sType:=VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
 fGraphicsPipelineCreateInfo.pNext:=nil;
 fGraphicsPipelineCreateInfo.flags:=aFlags;
 fGraphicsPipelineCreateInfo.stageCount:=length(aStages);
 fCountStages:=fGraphicsPipelineCreateInfo.stageCount;
 if fCountStages>0 then begin
  SetLength(fStages,fCountStages);
  for Index:=0 to fCountStages-1 do begin
   aStages[Index].Initialize;
   fStages[Index]:=aStages[Index].fPipelineShaderStageCreateInfo;
  end;
  fGraphicsPipelineCreateInfo.pStages:=@fStages[0];
 end else begin
  fGraphicsPipelineCreateInfo.pStages:=nil;
 end;
 fGraphicsPipelineCreateInfo.pVertexInputState:=@fVertexInputState.fVertexInputStateCreateInfo;
 fGraphicsPipelineCreateInfo.pInputAssemblyState:=@fInputAssemblyState.fInputAssemblyStateCreateInfo;
 fGraphicsPipelineCreateInfo.pTessellationState:=nil;
 fGraphicsPipelineCreateInfo.pViewportState:=@fViewPortState.fViewportStateCreateInfo;
 fGraphicsPipelineCreateInfo.pRasterizationState:=@fRasterizationState.fRasterizationStateCreateInfo;
 fGraphicsPipelineCreateInfo.pMultisampleState:=@fMultisampleState.fMultisampleStateCreateInfo;
 fGraphicsPipelineCreateInfo.pDepthStencilState:=@fDepthStencilState.fDepthStencilStateCreateInfo;
 fGraphicsPipelineCreateInfo.pColorBlendState:=@fColorBlendState.fColorBlendStateCreateInfo;
 fGraphicsPipelineCreateInfo.pDynamicState:=nil;
 if assigned(aLayout) then begin
  fGraphicsPipelineCreateInfo.layout:=aLayout.fPipelineLayoutHandle;
 end else begin
  fGraphicsPipelineCreateInfo.layout:=VK_NULL_HANDLE;
 end;
 if assigned(aRenderPass) then begin
  fGraphicsPipelineCreateInfo.renderPass:=aRenderPass.fRenderPassHandle;
 end else begin
  fGraphicsPipelineCreateInfo.renderPass:=VK_NULL_HANDLE;
 end;
 fGraphicsPipelineCreateInfo.subpass:=aSubPass;
 if assigned(aBasePipelineHandle) then begin
  fGraphicsPipelineCreateInfo.basePipelineHandle:=aBasePipelineHandle.fPipelineHandle;
 end else begin
  fGraphicsPipelineCreateInfo.basePipelineHandle:=VK_NULL_HANDLE;
 end;
 fGraphicsPipelineCreateInfo.basePipelineIndex:=aBasePipelineIndex;

 if assigned(aCache) then begin
  fPipelineCache:=aCache.fPipelineCacheHandle;
 end else begin
  fPipelineCache:=VK_NULL_HANDLE;
 end;

end;

destructor TpvVulkanGraphicsPipelineConstructor.Destroy;
begin
 SetLength(fStages,0);
 fVertexInputState.Free;
 fInputAssemblyState.Free;
 fTessellationState.Free;
 fViewPortState.Free;
 fRasterizationState.Free;
 fMultisampleState.Free;
 fDepthStencilState.Free;
 fColorBlendState.Free;
 fDynamicState.Free;
 inherited Destroy;
end;

procedure TpvVulkanGraphicsPipelineConstructor.Assign(const aFrom:TpvVulkanGraphicsPipelineConstructor);
begin
 fStages:=copy(aFrom.fStages);
 fCountStages:=aFrom.fCountStages;
 fVertexInputState.Assign(aFrom.fVertexInputState);
 fInputAssemblyState.Assign(aFrom.fInputAssemblyState);
 fTessellationState.Assign(aFrom.fTessellationState);
 fViewPortState.Assign(aFrom.fViewPortState);
 fRasterizationState.Assign(aFrom.fRasterizationState);
 fMultisampleState.Assign(aFrom.fMultisampleState);
 fDepthStencilState.Assign(aFrom.fDepthStencilState);
 fColorBlendState.Assign(aFrom.fColorBlendState);
 fDynamicState.Assign(aFrom.fDynamicState);
end;

function TpvVulkanGraphicsPipelineConstructor.AddStage(const aStage:TpvVulkanPipelineShaderStage):TpvInt32;
begin
 result:=fCountStages;
 inc(fCountStages);
 if length(fStages)<fCountStages then begin
  SetLength(fStages,fCountStages*2);
 end;
 aStage.Initialize;
 fStages[result]:=aStage.fPipelineShaderStageCreateInfo;
end;

function TpvVulkanGraphicsPipelineConstructor.AddStages(const aStages:array of TpvVulkanPipelineShaderStage):TpvInt32;
var Index:TpvInt32;
begin
 if length(aStages)>0 then begin
  result:=AddStage(aStages[0]);
  for Index:=1 to length(aStages)-1 do begin
   AddStage(aStages[Index]);
  end;
 end else begin
  result:=-1;
 end;
end;

function TpvVulkanGraphicsPipelineConstructor.AddVertexInputBindingDescription(const aVertexInputBindingDescription:TVkVertexInputBindingDescription):TpvInt32;
begin
 Assert(assigned(fVertexInputState));
 result:=fVertexInputState.AddVertexInputBindingDescription(aVertexInputBindingDescription);
end;

function TpvVulkanGraphicsPipelineConstructor.AddVertexInputBindingDescription(const aBinding,aStride:TpvUInt32;const aInputRate:TVkVertexInputRate):TpvInt32;
begin
 Assert(assigned(fVertexInputState));
 result:=fVertexInputState.AddVertexInputBindingDescription(aBinding,aStride,aInputRate);
end;

function TpvVulkanGraphicsPipelineConstructor.AddVertexInputBindingDescriptions(const aVertexInputBindingDescriptions:array of TVkVertexInputBindingDescription):TpvInt32;
begin
 Assert(assigned(fVertexInputState));
 result:=fVertexInputState.AddVertexInputBindingDescriptions(aVertexInputBindingDescriptions);
end;

function TpvVulkanGraphicsPipelineConstructor.AddVertexInputAttributeDescription(const aVertexInputAttributeDescription:TVkVertexInputAttributeDescription):TpvInt32;
begin
 Assert(assigned(fVertexInputState));
 result:=fVertexInputState.AddVertexInputAttributeDescription(aVertexInputAttributeDescription);
end;

function TpvVulkanGraphicsPipelineConstructor.AddVertexInputAttributeDescription(const aLocation,aBinding:TpvUInt32;const aFormat:TVkFormat;const aOffset:TpvUInt32):TpvInt32;
begin
 Assert(assigned(fVertexInputState));
 result:=fVertexInputState.AddVertexInputAttributeDescription(aLocation,aBinding,aFormat,aOffset);
end;

function TpvVulkanGraphicsPipelineConstructor.AddVertexInputAttributeDescriptions(const aVertexInputAttributeDescriptions:array of TVkVertexInputAttributeDescription):TpvInt32;
begin
 Assert(assigned(fVertexInputState));
 result:=fVertexInputState.AddVertexInputAttributeDescriptions(aVertexInputAttributeDescriptions);
end;

procedure TpvVulkanGraphicsPipelineConstructor.SetInputAssemblyState(const aTopology:TVkPrimitiveTopology;const aPrimitiveRestartEnable:boolean);
begin
 Assert(assigned(fInputAssemblyState));
 fInputAssemblyState.SetInputAssemblyState(aTopology,aPrimitiveRestartEnable);
end;

procedure TpvVulkanGraphicsPipelineConstructor.SetTessellationState(const aPatchControlPoints:TpvUInt32);
begin
 Assert(assigned(fTessellationState));
 fTessellationState.SetTessellationState(aPatchControlPoints);
end;

function TpvVulkanGraphicsPipelineConstructor.AddViewPort(const aViewPort:TVkViewport):TpvInt32;
begin
 Assert(assigned(fViewPortState));
 result:=fViewPortState.AddViewPort(aViewPort);
end;

function TpvVulkanGraphicsPipelineConstructor.AddViewPort(const pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth:TpvFloat):TpvInt32;
begin
 Assert(assigned(fViewPortState));
 result:=fViewPortState.AddViewPort(pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth);
end;

function TpvVulkanGraphicsPipelineConstructor.AddViewPorts(const aViewPorts:array of TVkViewport):TpvInt32;
begin
 Assert(assigned(fViewPortState));
 result:=fViewPortState.AddViewPorts(aViewPorts);
end;

function TpvVulkanGraphicsPipelineConstructor.AddScissor(const aScissor:TVkRect2D):TpvInt32;
begin
 Assert(assigned(fViewPortState));
 result:=fViewPortState.AddScissor(aScissor);
end;

function TpvVulkanGraphicsPipelineConstructor.AddScissor(const pX,pY:TpvInt32;const aWidth,aHeight:TpvUInt32):TpvInt32;
begin
 Assert(assigned(fViewPortState));
 result:=fViewPortState.AddScissor(pX,pY,aWidth,aHeight);
end;

function TpvVulkanGraphicsPipelineConstructor.AddScissors(const aScissors:array of TVkRect2D):TpvInt32;
begin
 Assert(assigned(fViewPortState));
 result:=fViewPortState.AddScissors(aScissors);
end;

procedure TpvVulkanGraphicsPipelineConstructor.SetRasterizationState(const aDepthClampEnable:boolean;
                                                                     const aRasterizerDiscardEnable:boolean;
                                                                     const aPolygonMode:TVkPolygonMode;
                                                                     const aCullMode:TVkCullModeFlags;
                                                                     const aFrontFace:TVkFrontFace;
                                                                     const aDepthBiasEnable:boolean;
                                                                     const aDepthBiasConstantFactor:TpvFloat;
                                                                     const aDepthBiasClamp:TpvFloat;
                                                                     const aDepthBiasSlopeFactor:TpvFloat;
                                                                     const aLineWidth:TpvFloat);
begin
 Assert(assigned(fRasterizationState));
 fRasterizationState.SetRasterizationState(aDepthClampEnable,
                                           aRasterizerDiscardEnable,
                                           aPolygonMode,
                                           aCullMode,
                                           aFrontFace,
                                           aDepthBiasEnable,
                                           aDepthBiasConstantFactor,
                                           aDepthBiasClamp,
                                           aDepthBiasSlopeFactor,
                                           aLineWidth);
end;

procedure TpvVulkanGraphicsPipelineConstructor.SetMultisampleState(const aRasterizationSamples:TVkSampleCountFlagBits;
                                                                   const aSampleShadingEnable:boolean;
                                                                   const aMinSampleShading:TpvFloat;
                                                                   const aSampleMask:array of TVkSampleMask;
                                                                   const aAlphaToCoverageEnable:boolean;
                                                                   const aAlphaToOneEnable:boolean);
begin
 Assert(assigned(fMultisampleState));
 fMultisampleState.SetMultisampleState(aRasterizationSamples,
                                       aSampleShadingEnable,
                                       aMinSampleShading,
                                       aSampleMask,
                                       aAlphaToCoverageEnable,
                                       aAlphaToOneEnable);
end;

procedure TpvVulkanGraphicsPipelineConstructor.SetDepthStencilState(const aDepthTestEnable:boolean;
                                                                    const aDepthWriteEnable:boolean;
                                                                    const aDepthCompareOp:TVkCompareOp;
                                                                    const aDepthBoundsTestEnable:boolean;
                                                                    const aStencilTestEnable:boolean;
                                                                    const aFront:TVkStencilOpState;
                                                                    const aBack:TVkStencilOpState;
                                                                    const aMinDepthBounds:TpvFloat;
                                                                    const aMaxDepthBounds:TpvFloat);
begin
 Assert(assigned(fDepthStencilState));
 fDepthStencilState.SetDepthStencilState(aDepthTestEnable,
                                         aDepthWriteEnable,
                                         aDepthCompareOp,
                                         aDepthBoundsTestEnable,
                                         aStencilTestEnable,
                                         aFront,
                                         aBack,
                                         aMinDepthBounds,
                                         aMaxDepthBounds);
end;

procedure TpvVulkanGraphicsPipelineConstructor.SetColorBlendState(const aLogicOpEnable:boolean;
                                                                  const aLogicOp:TVkLogicOp;
                                                                  const aBlendConstants:array of TpvFloat);
begin
 Assert(assigned(fColorBlendState));
 fColorBlendState.SetColorBlendState(aLogicOpEnable,
                                     aLogicOp,
                                     aBlendConstants);
end;

function TpvVulkanGraphicsPipelineConstructor.AddColorBlendAttachmentState(const aColorBlendAttachmentState:TVkPipelineColorBlendAttachmentState):TpvInt32;
begin
 Assert(assigned(fColorBlendState));
 result:=fColorBlendState.AddColorBlendAttachmentState(aColorBlendAttachmentState);
end;

function TpvVulkanGraphicsPipelineConstructor.AddColorBlendAttachmentState(const aBlendEnable:boolean;
                                                                           const aSrcColorBlendFactor:TVkBlendFactor;
                                                                           const aDstColorBlendFactor:TVkBlendFactor;
                                                                           const aColorBlendOp:TVkBlendOp;
                                                                           const aSrcAlphaBlendFactor:TVkBlendFactor;
                                                                           const aDstAlphaBlendFactor:TVkBlendFactor;
                                                                           const aAlphaBlendOp:TVkBlendOp;
                                                                           const aColorWriteMask:TVkColorComponentFlags):TpvInt32;
begin
 Assert(assigned(fColorBlendState));
 result:=fColorBlendState.AddColorBlendAttachmentState(aBlendEnable,
                                                       aSrcColorBlendFactor,
                                                       aDstColorBlendFactor,
                                                       aColorBlendOp,
                                                       aSrcAlphaBlendFactor,
                                                       aDstAlphaBlendFactor,
                                                       aAlphaBlendOp,
                                                       aColorWriteMask);
end;

function TpvVulkanGraphicsPipelineConstructor.AddColorBlendAttachmentStates(const aColorBlendAttachmentStates:array of TVkPipelineColorBlendAttachmentState):TpvInt32;
begin
 Assert(assigned(fColorBlendState));
 result:=fColorBlendState.AddColorBlendAttachmentStates(aColorBlendAttachmentStates);
end;

function TpvVulkanGraphicsPipelineConstructor.AddDynamicState(const aDynamicState:TVkDynamicState):TpvInt32;
begin
 Assert(assigned(fDynamicState));
 result:=fDynamicState.AddDynamicState(aDynamicState);
end;

function TpvVulkanGraphicsPipelineConstructor.AddDynamicStates(const aDynamicStates:array of TVkDynamicState):TpvInt32;
begin
 Assert(assigned(fDynamicState));
 result:=fDynamicState.AddDynamicStates(aDynamicStates);
end;

procedure TpvVulkanGraphicsPipelineConstructor.Initialize;
begin
 if fPipelineHandle=VK_NULL_HANDLE then begin

  fGraphicsPipelineCreateInfo.stageCount:=fCountStages;
  if fCountStages>0 then begin
   SetLength(fStages,fCountStages);
   fGraphicsPipelineCreateInfo.pStages:=@fStages[0];
  end else begin
   fGraphicsPipelineCreateInfo.pStages:=nil;
  end;

  fVertexInputState.Initialize;

  if fTessellationState.fTessellationStateCreateInfo.patchControlPoints>0 then begin
   fGraphicsPipelineCreateInfo.pTessellationState:=@fTessellationState.fTessellationStateCreateInfo;
  end;

  fViewPortState.Initialize;

  fMultisampleState.Initialize;

  fColorBlendState.Initialize;

  fDynamicState.Initialize;

  if fDynamicState.CountDynamicStates>0 then begin
   fGraphicsPipelineCreateInfo.pDynamicState:=@fDynamicState.fDynamicStateCreateInfo;
  end;

  HandleResultCode(fDevice.fDeviceVulkan.CreateGraphicsPipelines(fDevice.fDeviceHandle,fPipelineCache,1,@fGraphicsPipelineCreateInfo,fDevice.fAllocationCallbacks,@fPipelineHandle));

 end;

end;

constructor TpvVulkanGraphicsPipeline.Create(const aDevice:TpvVulkanDevice;
                                             const aCache:TpvVulkanPipelineCache;
                                             const aFlags:TVkPipelineCreateFlags;
                                             const aStages:array of TpvVulkanPipelineShaderStage;
                                             const aLayout:TpvVulkanPipelineLayout;
                                             const aRenderPass:TpvVulkanRenderPass;
                                             const aSubPass:TpvUInt32;
                                             const aBasePipelineHandle:TpvVulkanPipeline;
                                             const aBasePipelineIndex:TpvInt32);
begin
 inherited Create(aDevice);
 fGraphicsPipelineConstructor:=TpvVulkanGraphicsPipelineConstructor.Create(fDevice,
                                                                         aCache,
                                                                         aFlags,
                                                                         aStages,
                                                                         aLayout,
                                                                         aRenderPass,
                                                                         aSubPass,
                                                                         aBasePipelineHandle,
                                                                         aBasePipelineIndex);
end;

destructor TpvVulkanGraphicsPipeline.Destroy;
begin
 FreeAndNil(fGraphicsPipelineConstructor);
 inherited Destroy;
end;

procedure TpvVulkanGraphicsPipeline.Assign(const aFrom:TpvVulkanGraphicsPipeline);
begin
 fGraphicsPipelineConstructor.Assign(aFrom.fGraphicsPipelineConstructor);
end;

function TpvVulkanGraphicsPipeline.GetCountStages:TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fCountStages;
end;

function TpvVulkanGraphicsPipeline.GetVertexInputState:TpvVulkanPipelineVertexInputState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fVertexInputState;
end;

function TpvVulkanGraphicsPipeline.GetInputAssemblyState:TpvVulkanPipelineInputAssemblyState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fInputAssemblyState;
end;

function TpvVulkanGraphicsPipeline.GetTessellationState:TpvVulkanPipelineTessellationState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fTessellationState;
end;

function TpvVulkanGraphicsPipeline.GetViewPortState:TpvVulkanPipelineViewPortState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fViewPortState;
end;

function TpvVulkanGraphicsPipeline.GetRasterizationState:TpvVulkanPipelineRasterizationState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fRasterizationState;
end;

function TpvVulkanGraphicsPipeline.GetMultisampleState:TpvVulkanPipelineMultisampleState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fMultisampleState;
end;

function TpvVulkanGraphicsPipeline.GetDepthStencilState:TpvVulkanPipelineDepthStencilState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fDepthStencilState;
end;

function TpvVulkanGraphicsPipeline.GetColorBlendState:TpvVulkanPipelineColorBlendState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fColorBlendState;
end;

function TpvVulkanGraphicsPipeline.GetDynamicState:TpvVulkanPipelineDynamicState;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.fDynamicState;
end;

function TpvVulkanGraphicsPipeline.AddStage(const aStage:TpvVulkanPipelineShaderStage):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddStage(aStage);
end;

function TpvVulkanGraphicsPipeline.AddStages(const aStages:array of TpvVulkanPipelineShaderStage):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddStages(aStages);
end;

function TpvVulkanGraphicsPipeline.AddVertexInputBindingDescription(const aVertexInputBindingDescription:TVkVertexInputBindingDescription):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddVertexInputBindingDescription(aVertexInputBindingDescription);
end;

function TpvVulkanGraphicsPipeline.AddVertexInputBindingDescription(const aBinding,aStride:TpvUInt32;const aInputRate:TVkVertexInputRate):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddVertexInputBindingDescription(aBinding,aStride,aInputRate);
end;

function TpvVulkanGraphicsPipeline.AddVertexInputBindingDescriptions(const aVertexInputBindingDescriptions:array of TVkVertexInputBindingDescription):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddVertexInputBindingDescriptions(aVertexInputBindingDescriptions);
end;

function TpvVulkanGraphicsPipeline.AddVertexInputAttributeDescription(const aVertexInputAttributeDescription:TVkVertexInputAttributeDescription):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddVertexInputAttributeDescription(aVertexInputAttributeDescription);
end;

function TpvVulkanGraphicsPipeline.AddVertexInputAttributeDescription(const aLocation,aBinding:TpvUInt32;const aFormat:TVkFormat;const aOffset:TpvUInt32):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddVertexInputAttributeDescription(aLocation,aBinding,aFormat,aOffset);
end;

function TpvVulkanGraphicsPipeline.AddVertexInputAttributeDescriptions(const aVertexInputAttributeDescriptions:array of TVkVertexInputAttributeDescription):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddVertexInputAttributeDescriptions(aVertexInputAttributeDescriptions);
end;

procedure TpvVulkanGraphicsPipeline.SetInputAssemblyState(const aTopology:TVkPrimitiveTopology;const aPrimitiveRestartEnable:boolean);
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 fGraphicsPipelineConstructor.SetInputAssemblyState(aTopology,aPrimitiveRestartEnable);
end;

procedure TpvVulkanGraphicsPipeline.SetTessellationState(const aPatchControlPoints:TpvUInt32);
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 fGraphicsPipelineConstructor.SetTessellationState(aPatchControlPoints);
end;

function TpvVulkanGraphicsPipeline.AddViewPort(const aViewPort:TVkViewport):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddViewPort(aViewPort);
end;

function TpvVulkanGraphicsPipeline.AddViewPort(const pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth:TpvFloat):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddViewPort(pX,pY,aWidth,aHeight,aMinDepth,aMaxDepth);
end;

function TpvVulkanGraphicsPipeline.AddViewPorts(const aViewPorts:array of TVkViewport):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddViewPorts(aViewPorts);
end;

function TpvVulkanGraphicsPipeline.AddScissor(const aScissor:TVkRect2D):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddScissor(aScissor);
end;

function TpvVulkanGraphicsPipeline.AddScissor(const pX,pY:TpvInt32;const aWidth,aHeight:TpvUInt32):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddScissor(pX,pY,aWidth,aHeight);
end;

function TpvVulkanGraphicsPipeline.AddScissors(const aScissors:array of TVkRect2D):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddScissors(aScissors);
end;

procedure TpvVulkanGraphicsPipeline.SetRasterizationState(const aDepthClampEnable:boolean;
                                                          const aRasterizerDiscardEnable:boolean;
                                                          const aPolygonMode:TVkPolygonMode;
                                                          const aCullMode:TVkCullModeFlags;
                                                          const aFrontFace:TVkFrontFace;
                                                          const aDepthBiasEnable:boolean;
                                                          const aDepthBiasConstantFactor:TpvFloat;
                                                          const aDepthBiasClamp:TpvFloat;
                                                          const aDepthBiasSlopeFactor:TpvFloat;
                                                          const aLineWidth:TpvFloat);
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 fGraphicsPipelineConstructor.SetRasterizationState(aDepthClampEnable,
                                                    aRasterizerDiscardEnable,
                                                    aPolygonMode,
                                                    aCullMode,
                                                    aFrontFace,
                                                    aDepthBiasEnable,
                                                    aDepthBiasConstantFactor,
                                                    aDepthBiasClamp,
                                                    aDepthBiasSlopeFactor,
                                                    aLineWidth);
end;

procedure TpvVulkanGraphicsPipeline.SetMultisampleState(const aRasterizationSamples:TVkSampleCountFlagBits;
                                                        const aSampleShadingEnable:boolean;
                                                        const aMinSampleShading:TpvFloat;
                                                        const aSampleMask:array of TVkSampleMask;
                                                        const aAlphaToCoverageEnable:boolean;
                                                        const aAlphaToOneEnable:boolean);
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 fGraphicsPipelineConstructor.SetMultisampleState(aRasterizationSamples,
                                                  aSampleShadingEnable,
                                                  aMinSampleShading,
                                                  aSampleMask,
                                                  aAlphaToCoverageEnable,
                                                  aAlphaToOneEnable);
end;

procedure TpvVulkanGraphicsPipeline.SetDepthStencilState(const aDepthTestEnable:boolean;
                                                         const aDepthWriteEnable:boolean;
                                                         const aDepthCompareOp:TVkCompareOp;
                                                         const aDepthBoundsTestEnable:boolean;
                                                         const aStencilTestEnable:boolean;
                                                         const aFront:TVkStencilOpState;
                                                         const aBack:TVkStencilOpState;
                                                         const aMinDepthBounds:TpvFloat;
                                                         const aMaxDepthBounds:TpvFloat);
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 fGraphicsPipelineConstructor.SetDepthStencilState(aDepthTestEnable,
                                                   aDepthWriteEnable,
                                                   aDepthCompareOp,
                                                   aDepthBoundsTestEnable,
                                                   aStencilTestEnable,
                                                   aFront,
                                                   aBack,
                                                   aMinDepthBounds,
                                                   aMaxDepthBounds);
end;

procedure TpvVulkanGraphicsPipeline.SetColorBlendState(const aLogicOpEnable:boolean;
                                                       const aLogicOp:TVkLogicOp;
                                                       const aBlendConstants:array of TpvFloat);
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 fGraphicsPipelineConstructor.SetColorBlendState(aLogicOpEnable,
                                                 aLogicOp,
                                                 aBlendConstants);
end;

function TpvVulkanGraphicsPipeline.AddColorBlendAttachmentState(const aColorBlendAttachmentState:TVkPipelineColorBlendAttachmentState):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddColorBlendAttachmentState(aColorBlendAttachmentState);
end;

function TpvVulkanGraphicsPipeline.AddColorBlendAttachmentState(const aBlendEnable:boolean;
                                                                const aSrcColorBlendFactor:TVkBlendFactor;
                                                                const aDstColorBlendFactor:TVkBlendFactor;
                                                                const aColorBlendOp:TVkBlendOp;
                                                                const aSrcAlphaBlendFactor:TVkBlendFactor;
                                                                const aDstAlphaBlendFactor:TVkBlendFactor;
                                                                const aAlphaBlendOp:TVkBlendOp;
                                                                const aColorWriteMask:TVkColorComponentFlags):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddColorBlendAttachmentState(aBlendEnable,
                                                                   aSrcColorBlendFactor,
                                                                   aDstColorBlendFactor,
                                                                   aColorBlendOp,
                                                                   aSrcAlphaBlendFactor,
                                                                   aDstAlphaBlendFactor,
                                                                   aAlphaBlendOp,
                                                                   aColorWriteMask);
end;

function TpvVulkanGraphicsPipeline.AddColorBlendAttachmentStates(const aColorBlendAttachmentStates:array of TVkPipelineColorBlendAttachmentState):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddColorBlendAttachmentStates(aColorBlendAttachmentStates);
end;

function TpvVulkanGraphicsPipeline.AddDynamicState(const aDynamicState:TVkDynamicState):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddDynamicState(aDynamicState);
end;

function TpvVulkanGraphicsPipeline.AddDynamicStates(const aDynamicStates:array of TVkDynamicState):TpvInt32;
begin
 Assert(assigned(fGraphicsPipelineConstructor));
 result:=fGraphicsPipelineConstructor.AddDynamicStates(aDynamicStates);
end;

procedure TpvVulkanGraphicsPipeline.Initialize;
begin
 if fPipelineHandle=VK_NULL_HANDLE then begin
  Assert(assigned(fGraphicsPipelineConstructor));
  fGraphicsPipelineConstructor.Initialize;
  fPipelineHandle:=fGraphicsPipelineConstructor.fPipelineHandle;
  fGraphicsPipelineConstructor.fPipelineHandle:=VK_NULL_HANDLE;
 end;
end;

procedure TpvVulkanGraphicsPipeline.FreeMemory;
begin
 FreeAndNil(fGraphicsPipelineConstructor);
end;

constructor TpvVulkanTexture.Create;
begin
 raise EpvVulkanTextureException.Create('Invalid constructor');
end;

constructor TpvVulkanTexture.CreateFromMemory(const aDevice:TpvVulkanDevice;
                                              const aGraphicsQueue:TpvVulkanQueue;
                                              const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                              const aGraphicsFence:TpvVulkanFence;
                                              const aTransferQueue:TpvVulkanQueue;
                                              const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                              const aTransferFence:TpvVulkanFence;
                                              const aFormat:TVkFormat;
                                              const aSampleCount:TVkSampleCountFlagBits;
                                              const aWidth:TpvInt32;
                                              const aHeight:TpvInt32;
                                              const aDepth:TpvInt32;
                                              const aCountArrayLayers:TpvInt32;
                                              const aCountFaces:TpvInt32;
                                              const aCountMipMaps:TpvInt32;
                                              const aUsageFlags:TpvVulkanTextureUsageFlags;
                                              const aData:TpvPointer;
                                              const aDataSize:TVkSizeInt;
                                              const aMipMapSizeStored:boolean;
                                              const aSwapEndianness:boolean;
                                              const aSwapEndiannessTexels:TpvInt32;
                                              const aDDSStructure:boolean=true);
var MaxDimension,MaxMipMapLevels:TpvInt32;
    FormatProperties:TVkFormatProperties;
    Usage:TVkImageUsageFlags;
    ImageCreateFlags:TVkImageCreateFlags;
    ImageType:TVkImageType;
    MemoryRequirements:TVkMemoryRequirements;
    ImageBlit:TVkImageBlit;
begin

 inherited Create;

 fDevice:=aDevice;

 fFormat:=VK_FORMAT_UNDEFINED;

 fImageLayout:=VK_IMAGE_LAYOUT_UNDEFINED;

 fImage:=nil;

 fImageView:=nil;

 fSampler:=nil;

 fMemoryBlock:=nil;

 fWidth:=0;
 fHeight:=0;
 fDepth:=0;

 fCountArrayLayers:=0;

 fCountMipMaps:=0;

 fSampleCount:=VK_SAMPLE_COUNT_1_BIT;

 fUsage:=vtufUndefined;

 fUsageFlags:=[];

 fWrapModeU:=vtwmRepeat;
 fWrapModeV:=vtwmRepeat;
 fWrapModeW:=vtwmRepeat;

 fFilterMode:=vtfmNearest;

 fBorderColor:=VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK;

 fMaxAnisotropy:=1.0;

 if (aDepth<0) or (aCountArrayLayers<0) or (aCountFaces<1) then begin
  raise EpvVulkanTextureException.Create('Invalid parameters');
 end;
 if (aWidth<1) or (aWidth>32768) or (aHeight<1) or (aHeight>32768) or (aDepth<0) or (aDepth>32768) then begin
  if aDepth>0 then begin
   raise EpvVulkanTextureException.Create('Invalid texture size ('+IntToStr(aWidth)+'x'+IntToStr(aHeight)+'x'+IntToStr(aDepth)+')');
  end else begin
   raise EpvVulkanTextureException.Create('Invalid texture size ('+IntToStr(aWidth)+'x'+IntToStr(aHeight)+')');
  end;
 end;
 if not (aCountFaces in [1,6]) then begin
  raise EpvVulkanTextureException.Create('Cube maps must have 6 faces');
 end;
 if (aCountFaces<>1) and (aWidth<>aHeight) then begin
  raise EpvVulkanTextureException.Create('Cube maps must be square ('+IntToStr(aWidth)+'x'+IntToStr(aHeight)+')');
 end;
{if (aDepth>1) or (aCountArrayElements>1) then begin
  raise EpvVulkanTextureException.Create('3D array textures not supported yet');
 end;}

 MaxDimension:=Max(1,Max(aWidth,Max(aHeight,aDepth)));
 MaxMipMapLevels:=VulkanIntLog2(MaxDimension)+1;
 if aCountMipMaps>MaxMipMapLevels then begin
  raise EpvVulkanTextureException.Create('Too many mip levels ('+IntToStr(aCountMipMaps)+' > '+IntToStr(MaxMipMapLevels)+')');
 end;

 FormatProperties:=fDevice.fPhysicalDevice.GetFormatProperties(aFormat);

 if (vtufSampled in aUsageFlags) and ((FormatProperties.optimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_SAMPLED_IMAGE_BIT))=0) then begin
  raise EpvVulkanTextureException.Create('Texture format '+IntToStr(TpvInt32(aFormat))+' can''t be sampled');
 end;

 if (vtufColorAttachment in aUsageFlags) and ((FormatProperties.optimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_COLOR_ATTACHMENT_BIT))=0) then begin
  raise EpvVulkanTextureException.Create('Texture format '+IntToStr(TpvInt32(aFormat))+' can''t be rendered to');
 end;

 if (vtufStorage in aUsageFlags) and ((FormatProperties.optimalTilingFeatures and TVkFormatFeatureFlags(VK_FORMAT_FEATURE_STORAGE_IMAGE_BIT))=0) then begin
  raise EpvVulkanTextureException.Create('Texture format '+IntToStr(TpvInt32(aFormat))+' can''t be used for storage');
 end;

 if aCountMipMaps>=1 then begin
  fCountStorageLevels:=aCountMipMaps;
  fCountDataLevels:=aCountMipMaps;
 end else begin
  fCountStorageLevels:=MaxMipMapLevels;
  fCountDataLevels:=1;
 end;

 fTotalCountArrayLayers:=Max(1,aCountFaces)*Max(1,aCountArrayLayers);

 fWidth:=aWidth;
 fHeight:=aHeight;
 fDepth:=aDepth;
 fCountFaces:=aCountFaces;
 fCountArrayLayers:=aCountArrayLayers;
 fCountMipMaps:=aCountMipMaps;
 fSampleCount:=aSampleCount;
 fUsage:=vtufUndefined;
 fUsageFlags:=aUsageFlags;
 fWrapModeU:=vtwmRepeat;
 fWrapModeV:=vtwmRepeat;
 fWrapModeW:=vtwmRepeat;
 if fCountStorageLevels>1 then begin
  fFilterMode:=vtfmBilinear;
 end else begin
  fFilterMode:=vtfmLinear;
 end;
 fBorderColor:=VK_BORDER_COLOR_FLOAT_OPAQUE_BLACK;
 fMaxAnisotropy:=1.0;
 fFormat:=aFormat;

 Usage:=0;
 if (vtufTransferDst in fUsageFlags) or assigned(aData) then begin
  Usage:=Usage or TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_DST_BIT);
 end;
 if (vtufTransferSrc in fUsageFlags) or (assigned(aData) and (aCountMipMaps<0)) then begin
  Usage:=Usage or TVkImageUsageFlags(VK_IMAGE_USAGE_TRANSFER_SRC_BIT);
 end;
 if vtufSampled in fUsageFlags then begin
  Usage:=Usage or TVkImageUsageFlags(VK_IMAGE_USAGE_SAMPLED_BIT);
 end;
 if vtufColorAttachment in fUsageFlags then begin
  Usage:=Usage or TVkImageUsageFlags(VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
 end;
 if vtufStorage in fUsageFlags then begin
  Usage:=Usage or TVkImageUsageFlags(VK_IMAGE_USAGE_STORAGE_BIT);
 end;

 ImageCreateFlags:=0;
 if aCountFaces=6 then begin
  ImageCreateFlags:=ImageCreateFlags or TVkImageCreateFlags(VK_IMAGE_CREATE_CUBE_COMPATIBLE_BIT);
 end;

 if aDepth>0 then begin
  ImageType:=VK_IMAGE_TYPE_3D;
 end else begin
  ImageType:=VK_IMAGE_TYPE_2D;
 end;

 fImage:=TpvVulkanImage.Create(fDevice,
                               ImageCreateFlags,
                               ImageType,
                               fFormat,
                               Max(1,fWidth),
                               Max(1,fHeight),
                               Max(1,fDepth),
                               Max(1,fCountStorageLevels),
                               Max(1,fTotalCountArrayLayers),
                               fSampleCount,
                               VK_IMAGE_TILING_OPTIMAL,
                               Usage,
                               VK_SHARING_MODE_EXCLUSIVE,
                               0,
                               nil,
                               VK_IMAGE_LAYOUT_UNDEFINED
                              );

 fDevice.Commands.GetImageMemoryRequirements(fDevice.fDeviceHandle,fImage.fImageHandle,@MemoryRequirements);

 fMemoryBlock:=fDevice.fMemoryManager.AllocateMemoryBlock([],
                                                          MemoryRequirements.size,
                                                          MemoryRequirements.alignment,
                                                          MemoryRequirements.memoryTypeBits,
                                                          TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                                          0,
                                                          0,
                                                          0,
                                                          0,
                                                          0,
                                                          vdmatImageOptimal);
 if not assigned(fMemoryBlock) then begin
  raise EpvVulkanMemoryAllocationException.Create('Memory for texture couldn''t be allocated!');
 end;

 HandleResultCode(fDevice.fDeviceVulkan.BindImageMemory(fDevice.fDeviceHandle,
                                                        fImage.fImageHandle,
                                                        fMemoryBlock.fMemoryChunk.fMemoryHandle,
                                                        fMemoryBlock.fOffset));

 Upload(aGraphicsQueue,
        aGraphicsCommandBuffer,
        aGraphicsFence,
        aTransferQueue,
        aTransferCommandBuffer,
        aTransferFence,
        aData,
        aDataSize,
        aMipMapSizeStored,
        aSwapEndianness,
        aSwapEndiannessTexels,
        aDDSStructure);

 fUsage:=vtufSampled;
 fImageLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;

 if aDepth>0 then begin
  fImageViewType:=VK_IMAGE_VIEW_TYPE_3D;
 end else begin
  if aCountFaces>1 then begin
   if aCountArrayLayers>0 then begin
    fImageViewType:=VK_IMAGE_VIEW_TYPE_CUBE_ARRAY;
   end else begin
    fImageViewType:=VK_IMAGE_VIEW_TYPE_CUBE;
   end;
  end else begin
   if aCountArrayLayers>0 then begin
    fImageViewType:=VK_IMAGE_VIEW_TYPE_2D_ARRAY;
   end else begin
    fImageViewType:=VK_IMAGE_VIEW_TYPE_2D;
   end;
  end;
 end;

 fImageView:=TpvVulkanImageView.Create(fDevice,
                                       fImage,
                                       fImageViewType,
                                       fFormat,
                                       VK_COMPONENT_SWIZZLE_IDENTITY,
                                       VK_COMPONENT_SWIZZLE_IDENTITY,
                                       VK_COMPONENT_SWIZZLE_IDENTITY,
                                       VK_COMPONENT_SWIZZLE_IDENTITY,
                                       TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT),
                                       0,
                                       Max(1,fCountStorageLevels),
                                       0,
                                       Max(1,fTotalCountArrayLayers));


 if assigned(fSampler) then begin
  fDescriptorImageInfo.sampler:=fSampler.fSamplerHandle;
 end else begin
  fDescriptorImageInfo.sampler:=VK_NULL_HANDLE;
 end;
 if assigned(fImageView) then begin
  fDescriptorImageInfo.imageView:=fImageView.fImageViewHandle;
 end else begin
  fDescriptorImageInfo.imageView:=VK_NULL_HANDLE;
 end;
 fDescriptorImageInfo.imageLayout:=fImageLayout;

end;

constructor TpvVulkanTexture.CreateFromStream(const aDevice:TpvVulkanDevice;
                                              const aGraphicsQueue:TpvVulkanQueue;
                                              const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                              const aGraphicsFence:TpvVulkanFence;
                                              const aTransferQueue:TpvVulkanQueue;
                                              const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                              const aTransferFence:TpvVulkanFence;
                                              const aFormat:TVkFormat;
                                              const aSampleCount:TVkSampleCountFlagBits;
                                              const aWidth:TpvInt32;
                                              const aHeight:TpvInt32;
                                              const aDepth:TpvInt32;
                                              const aCountArrayLayers:TpvInt32;
                                              const aCountFaces:TpvInt32;
                                              const aCountMipMaps:TpvInt32;
                                              const aUsageFlags:TpvVulkanTextureUsageFlags;
                                              const aStream:TStream;
                                              const aMipMapSizeStored:boolean;
                                              const aSwapEndianness:boolean;
                                              const aSwapEndiannessTexels:TpvInt32;
                                              const aDDSStructure:boolean=true);
var Data:TpvPointer;
    DataSize:TpvUInt32;
begin
 DataSize:=aStream.Size;
 GetMem(Data,DataSize);
 try
  if TpvInt64(aStream.Read(Data^,DataSize))<>TpvInt64(DataSize) then begin
   raise EpvVulkanTextureException.Create('Stream read error');
  end;
  CreateFromMemory(aDevice,
                   aGraphicsQueue,
                   aGraphicsCommandBuffer,
                   aGraphicsFence,
                   aTransferQueue,
                   aTransferCommandBuffer,
                   aTransferFence,
                   aFormat,
                   aSampleCount,
                   aWidth,
                   aHeight,
                   aDepth,
                   aCountArrayLayers,
                   aCountFaces,
                   aCountMipMaps,
                   aUsageFlags,
                   Data,
                   DataSize,
                   aMipMapSizeStored,
                   aSwapEndianness,
                   aSwapEndiannessTexels,
                   aDDSStructure);
 finally
  FreeMem(Data);
 end;
end;

constructor TpvVulkanTexture.CreateFromKTX(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aStream:TStream);
type PKTXIdentifier=^TKTXIdentifier;
     TKTXIdentifier=array[0..11] of TpvUInt8;
     PKTXHeader=^TKTXHeader;
     TKTXHeader=packed record
      Identifier:TKTXIdentifier;
      Endianness:TpvUInt32;
      GLType:TpvUInt32;
      GLTypeSize:TpvUInt32;
      GLFormat:TpvUInt32;
      GLInternalFormat:TpvUInt32;
      GLBaseInternalFormat:TpvUInt32;
      PixelWidth:TpvUInt32;
      PixelHeight:TpvUInt32;
      PixelDepth:TpvUInt32;
      NumberOfArrayElements:TpvUInt32;
      NumberOfFaces:TpvUInt32;
      NumberOfMipMapLevels:TpvUInt32;
      BytesOfKeyValueData:TpvUInt32;
     end;
 function Swap16(x:TpvUInt16):TpvUInt16;
 begin
  result:=((x and $ff) shl 8) or ((x and $ff00) shr 8);
 end;
 function Swap32(x:TpvUInt32):TpvUInt32;
 begin
  result:=(Swap16(x and $ffff) shl 16) or Swap16((x and $ffff0000) shr 16);
 end;
var KTXHeader:TKTXHeader;
    MustSwap:boolean;
    NumberOfArrayElements:TpvUInt32;
    NumberOfFaces:TpvUInt32;
    NumberOfMipMapLevels:TpvUInt32;
    Data:TpvPointer;
    DataSize:TVkSizeInt;
    NewPosition:TpvInt64;
begin

 if aStream.Read(KTXHeader,SizeOf(TKTXHeader))<>SizeOf(TKTXHeader) then begin
  raise EpvVulkanTextureException.Create('Stream read error');
 end;

 if (KTXHeader.Identifier[0]<>$ab) or
    (KTXHeader.Identifier[1]<>$4b) or
    (KTXHeader.Identifier[2]<>$54) or
    (KTXHeader.Identifier[3]<>$58) or
    (KTXHeader.Identifier[4]<>$20) or
    (KTXHeader.Identifier[5]<>$31) or
    (KTXHeader.Identifier[6]<>$31) or
    (KTXHeader.Identifier[7]<>$bb) or
    (KTXHeader.Identifier[8]<>$0d) or
    (KTXHeader.Identifier[9]<>$0a) or
    (KTXHeader.Identifier[10]<>$1a) or
    (KTXHeader.Identifier[11]<>$0a) then begin
  raise EpvVulkanTextureException.Create('Invalid KTX stream');
 end;

 MustSwap:=false;
 case KTXHeader.Endianness of
  $01020304:begin
   MustSwap:=true;
   KTXHeader.GLType:=Swap32(KTXHeader.GLType);
   KTXHeader.GLTypeSize:=Swap32(KTXHeader.GLTypeSize);
   KTXHeader.GLFormat:=Swap32(KTXHeader.GLFormat);
   KTXHeader.GLInternalFormat:=Swap32(KTXHeader.GLInternalFormat);
   KTXHeader.GLBaseInternalFormat:=Swap32(KTXHeader.GLBaseInternalFormat);
   KTXHeader.PixelWidth:=Swap32(KTXHeader.PixelWidth);
   KTXHeader.PixelHeight:=Swap32(KTXHeader.PixelHeight);
   KTXHeader.PixelDepth:=Swap32(KTXHeader.PixelDepth);
   KTXHeader.NumberOfArrayElements:=Swap32(KTXHeader.NumberOfArrayElements);
   KTXHeader.NumberOfFaces:=Swap32(KTXHeader.NumberOfFaces);
   KTXHeader.NumberOfMipmapLevels:=Swap32(KTXHeader.NumberOfMipmapLevels);
   KTXHeader.BytesOfKeyValueData:=Swap32(KTXHeader.BytesOfKeyValueData);
   if not (KTXHeader.GLTypeSize in [1,2,4]) then begin
    exit;
   end;
  end;
  $04030201:begin
  end;
  else begin
   exit;
  end;
 end;

 if (KTXHeader.GLType=0)<>(KTXHeader.GLFormat=0) then begin
  raise EpvVulkanTextureException.Create('Invalid KTX stream');
 end;
 if (KTXHeader.PixelWidth=0) or ((KTXHeader.PixelDepth>0) and (KTXHeader.PixelHeight=0)) then begin
  raise EpvVulkanTextureException.Create('Invalid KTX stream');
 end;
 if not ((KTXHeader.GLFormat=0) or (KTXHeader.GLTypeSize in [1,2,4,8])) then begin
  raise EpvVulkanTextureException.Create('Invalid KTX stream');
 end;
 if not ((KTXHeader.GLFormat=0) or (KTXHeader.GLFormat=KTXHeader.GLBaseInternalFormat)) then begin
  raise EpvVulkanTextureException.Create('Invalid KTX stream');
 end;
 if not ((KTXHeader.GLFormat<>0) or (KTXHeader.GLTypeSize=1)) then begin
  raise EpvVulkanTextureException.Create('Invalid KTX stream');
 end;

 NumberOfArrayElements:=Max(1,KTXHeader.NumberOfArrayElements);
 NumberOfFaces:=Max(1,KTXHeader.NumberOfFaces);
 NumberOfMipMapLevels:=KTXHeader.NumberOfMipMapLevels;

 if KTXHeader.BytesOfKeyValueData>0 then begin
  NewPosition:=aStream.Position+KTXHeader.BytesOfKeyValueData;
  if aStream.Seek(NewPosition,soBeginning)<>NewPosition then begin
   raise EpvVulkanTextureException.Create('Stream seek error');
  end;
 end;

 DataSize:=aStream.Size-aStream.Position;

 GetMem(Data,DataSize);
 try
  if aStream.Read(Data^,DataSize)<>DataSize then begin
   raise EpvVulkanTextureException.Create('Stream read error');
  end;
  CreateFromMemory(aDevice,
                   aGraphicsQueue,
                   aGraphicsCommandBuffer,
                   aGraphicsFence,
                   aTransferQueue,
                   aTransferCommandBuffer,
                   aTransferFence,
                   VulkanGetFormatFromOpenGLInternalFormat(KTXHeader.GLInternalFormat),
                   VK_SAMPLE_COUNT_1_BIT,
                   Max(1,KTXHeader.PixelWidth),
                   Max(1,KTXHeader.PixelHeight),
                   Max(1,KTXHeader.PixelDepth),
                   IfThen(NumberOfArrayElements=1,0,NumberOfArrayElements),
                   NumberOfFaces,
                   NumberOfMipMapLevels,
                   [vtufSampled],
                   Data,
                   DataSize,
                   true,
                   MustSwap,
                   KTXHeader.GLTypeSize,
                   false);
 finally
  FreeMem(Data);
 end;

end;

constructor TpvVulkanTexture.CreateFromDDS(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aStream:TStream);
const DDS_MAGIC=$20534444;
      DDSD_CAPS=$00000001;
      DDSD_HEIGHT=$00000002;
      DDSD_WIDTH=$00000004;
      DDSD_PITCH=$00000008;
      DDSD_PIXELFORMAT=$00001000;
      DDSD_MIPMAPCOUNT=$00020000;
      DDSD_LINEARSIZE=$00080000;
      DDSD_DEPTH=$00800000;
      DDPF_ALPHAPIXELS=$00000001;
      DDPF_ALPHA=$00000002;
      DDPF_FOURCC=$00000004;
      DDPF_INDEXED=$00000020;
      DDPF_RGB=$00000040;
      DDPF_YUV=$00000200;
      DDPF_LUMINANCE=$00020000;
      DDSCAPS_COMPLEX=$00000008;
      DDSCAPS_TEXTURE=$00001000;
      DDSCAPS_MIPMAP=$00400000;
      DDSCAPS2_CUBEMAP=$00000200;
      DDSCAPS2_CUBEMAP_POSITIVEX=$00000400;
      DDSCAPS2_CUBEMAP_NEGATIVEX=$00000800;
      DDSCAPS2_CUBEMAP_POSITIVEY=$00001000;
      DDSCAPS2_CUBEMAP_NEGATIVEY=$00002000;
      DDSCAPS2_CUBEMAP_POSITIVEZ=$00004000;
      DDSCAPS2_CUBEMAP_NEGATIVEZ=$00008000;
      DDSCAPS2_VOLUME=$00200000;
      D3DFMT_DXT1=$31545844;
      D3DFMT_DXT2=$32545844;
      D3DFMT_DXT3=$33545844;
      D3DFMT_DXT4=$34545844;
      D3DFMT_DXT5=$35545844;
      D3DFMT_ATI1=$31495441;
      D3DFMT_ATI2=$32495441;
      D3DFMT_BC4U=$55344342;
      D3DFMT_BC4S=$53344342;
      D3DFMT_BC5U=$55354342;
      D3DFMT_BC5S=$53354342;
      D3DFMT_RXGB=$42475852;
      D3DFMT_DX10=$30315844;
      DXGI_FORMAT_UNKNOWN=0;
      DXGI_FORMAT_R32G32B32A32_TYPELESS=1;
      DXGI_FORMAT_R32G32B32A32_FLOAT=2;
      DXGI_FORMAT_R32G32B32A32_UINT=3;
      DXGI_FORMAT_R32G32B32A32_SINT=4;
      DXGI_FORMAT_R32G32B32_TYPELESS=5;
      DXGI_FORMAT_R32G32B32_FLOAT=6;
      DXGI_FORMAT_R32G32B32_UINT=7;
      DXGI_FORMAT_R32G32B32_SINT=8;
      DXGI_FORMAT_R16G16B16A16_TYPELESS=9;
      DXGI_FORMAT_R16G16B16A16_FLOAT=10;
      DXGI_FORMAT_R16G16B16A16_UNORM=11;
      DXGI_FORMAT_R16G16B16A16_UINT=12;
      DXGI_FORMAT_R16G16B16A16_SNORM=13;
      DXGI_FORMAT_R16G16B16A16_SINT=14;
      DXGI_FORMAT_R32G32_TYPELESS=15;
      DXGI_FORMAT_R32G32_FLOAT=16;
      DXGI_FORMAT_R32G32_UINT=17;
      DXGI_FORMAT_R32G32_SINT=18;
      DXGI_FORMAT_R32G8X24_TYPELESS=19;
      DXGI_FORMAT_D32_FLOAT_S8X24_UINT=20;
      DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS=21;
      DXGI_FORMAT_X32_TYPELESS_G8X24_UINT=22;
      DXGI_FORMAT_R10G10B10A2_TYPELESS=23;
      DXGI_FORMAT_R10G10B10A2_UNORM=24;
      DXGI_FORMAT_R10G10B10A2_UINT=25;
      DXGI_FORMAT_R11G11B10_FLOAT=26;
      DXGI_FORMAT_R8G8B8A8_TYPELESS=27;
      DXGI_FORMAT_R8G8B8A8_UNORM=28;
      DXGI_FORMAT_R8G8B8A8_UNORM_SRGB=29;
      DXGI_FORMAT_R8G8B8A8_UINT=30;
      DXGI_FORMAT_R8G8B8A8_SNORM=31;
      DXGI_FORMAT_R8G8B8A8_SINT=32;
      DXGI_FORMAT_R16G16_TYPELESS=33;
      DXGI_FORMAT_R16G16_FLOAT=34;
      DXGI_FORMAT_R16G16_UNORM=35;
      DXGI_FORMAT_R16G16_UINT=36;
      DXGI_FORMAT_R16G16_SNORM=37;
      DXGI_FORMAT_R16G16_SINT=38;
      DXGI_FORMAT_R32_TYPELESS=39;
      DXGI_FORMAT_D32_FLOAT=40;
      DXGI_FORMAT_R32_FLOAT=41;
      DXGI_FORMAT_R32_UINT=42;
      DXGI_FORMAT_R32_SINT=43;
      DXGI_FORMAT_R24G8_TYPELESS=44;
      DXGI_FORMAT_D24_UNORM_S8_UINT=45;
      DXGI_FORMAT_R24_UNORM_X8_TYPELESS=46;
      DXGI_FORMAT_X24_TYPELESS_G8_UINT=47;
      DXGI_FORMAT_R8G8_TYPELESS=48;
      DXGI_FORMAT_R8G8_UNORM=49;
      DXGI_FORMAT_R8G8_UINT=50;
      DXGI_FORMAT_R8G8_SNORM=51;
      DXGI_FORMAT_R8G8_SINT=52;
      DXGI_FORMAT_R16_TYPELESS=53;
      DXGI_FORMAT_R16_FLOAT=54;
      DXGI_FORMAT_D16_UNORM=55;
      DXGI_FORMAT_R16_UNORM=56;
      DXGI_FORMAT_R16_UINT=57;
      DXGI_FORMAT_R16_SNORM=58;
      DXGI_FORMAT_R16_SINT=59;
      DXGI_FORMAT_R8_TYPELESS=60;
      DXGI_FORMAT_R8_UNORM=61;
      DXGI_FORMAT_R8_UINT=62;
      DXGI_FORMAT_R8_SNORM=63;
      DXGI_FORMAT_R8_SINT=64;
      DXGI_FORMAT_A8_UNORM=65;
      DXGI_FORMAT_R1_UNORM=66;
      DXGI_FORMAT_R9G9B9E5_SHAREDEXP=67;
      DXGI_FORMAT_R8G8_B8G8_UNORM=68;
      DXGI_FORMAT_G8R8_G8B8_UNORM=69;
      DXGI_FORMAT_BC1_TYPELESS=70;
      DXGI_FORMAT_BC1_UNORM=71;
      DXGI_FORMAT_BC1_UNORM_SRGB=72;
      DXGI_FORMAT_BC2_TYPELESS=73;
      DXGI_FORMAT_BC2_UNORM=74;
      DXGI_FORMAT_BC2_UNORM_SRGB=75;
      DXGI_FORMAT_BC3_TYPELESS=76;
      DXGI_FORMAT_BC3_UNORM=77;
      DXGI_FORMAT_BC3_UNORM_SRGB=78;
      DXGI_FORMAT_BC4_TYPELESS=79;
      DXGI_FORMAT_BC4_UNORM=80;
      DXGI_FORMAT_BC4_SNORM=81;
      DXGI_FORMAT_BC5_TYPELESS=82;
      DXGI_FORMAT_BC5_UNORM=83;
      DXGI_FORMAT_BC5_SNORM=84;
      DXGI_FORMAT_B5G6R5_UNORM=85;
      DXGI_FORMAT_B5G5R5A1_UNORM=86;
      DXGI_FORMAT_B8G8R8A8_UNORM=87;
      DXGI_FORMAT_B8G8R8X8_UNORM=88;
      DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM=89;
      DXGI_FORMAT_B8G8R8A8_TYPELESS=90;
      DXGI_FORMAT_B8G8R8A8_UNORM_SRGB=91;
      DXGI_FORMAT_B8G8R8X8_TYPELESS=92;
      DXGI_FORMAT_B8G8R8X8_UNORM_SRGB=93;
      DXGI_FORMAT_BC6H_TYPELESS=94;
      DXGI_FORMAT_BC6H_UF16=95;
      DXGI_FORMAT_BC6H_SF16=96;
      DXGI_FORMAT_BC7_TYPELESS=97;
      DXGI_FORMAT_BC7_UNORM=98;
      DXGI_FORMAT_BC7_UNORM_SRGB=99;
      DXGI_FORMAT_AYUV=100;
      DXGI_FORMAT_Y410=101;
      DXGI_FORMAT_Y416=102;
      DXGI_FORMAT_NV12=103;
      DXGI_FORMAT_P010=104;
      DXGI_FORMAT_P016=105;
      DXGI_FORMAT_420_OPAQUE=106;
      DXGI_FORMAT_YUY2=107;
      DXGI_FORMAT_Y210=108;
      DXGI_FORMAT_Y216=109;
      DXGI_FORMAT_NV11=110;
      DXGI_FORMAT_AI44=111;
      DXGI_FORMAT_IA44=112;
      DXGI_FORMAT_P8=113;
      DXGI_FORMAT_A8P8=114;
      DXGI_FORMAT_B4G4R4A4_UNORM=115;
type PDDSPixelFormat=^TDDSPixelFormat;
     TDDSPixelFormat=packed record
      dwSize:TpvUInt32;
      dwFlags:TpvUInt32;
      dwFourCC:TpvUInt32;
      dwRGBBitCount:TpvUInt32;
      dwRBitMask:TpvUInt32;
      dwGBitMask:TpvUInt32;
      dwBBitMask:TpvUInt32;
      dwABitMask:TpvUInt32;
     end;
     PDDSCaps=^TDDSCaps;
     TDDSCaps=packed record
      dwCaps1:TpvUInt32;
      dwCaps2:TpvUInt32;
      dwDDSX:TpvUInt32;
      dwReserved:TpvUInt32;
     end;
     PDDSHeader=^TDDSHeader;
     TDDSHeader=packed record
      dwMagic:TpvUInt32;
      dwSize:TpvUInt32;
      dwFlags:TpvUInt32;
      dwHeight:TpvUInt32;
      dwWidth:TpvUInt32;
      dwPitchOrLinearSize:TpvUInt32;
      dwDepth:TpvUInt32;
      dwMipMapCount:TpvUInt32;
      dwReserved:array[0..10] of TpvUInt32;
      PixelFormat:TDDSPixelFormat;
      Caps:TDDSCaps;
      dwReserved2:TpvUInt32;
     end;
     PDDSHeaderDX10=^TDDSHeaderDX10;
     TDDSHeaderDX10=packed record
      dxgiFormat:TpvUInt32;
      ResourceDimension:TpvUInt32;
      MiscFlag:TpvUInt32;
      ArraySize:TpvUInt32;
      Reserved:TpvUInt32;
     end;
var Header:TDDSHeader;
    HeaderDX10:TDDSHeaderDX10;
    ImageWidth,ImageHeight,ImageDepth,ImageMipMaps,ImageFaces,ImageArrayElements:TpvUInt32;
    ImageFormat:TVkFormat;
    IsVolume:boolean;
    DataSize:TVkSizeInt;
    Data:TpvPointer;
begin
 if aStream.Read(Header,SizeOf(TDDSHeader))<>SizeOf(TDDSHeader) then begin
  raise EpvVulkanTextureException.Create('Invalid DDS stream');
 end;
 if ((Header.dwMagic<>DDS_MAGIC) or (Header.dwSize<>124) or ((Header.dwFlags and DDSD_PIXELFORMAT)=0) or ((Header.dwFlags and DDSD_CAPS)=0)) then begin
  raise EpvVulkanTextureException.Create('Invalid DDS stream');
 end;
 if (Header.dwFlags and DDSD_WIDTH)<>0 then begin
  ImageWidth:=Header.dwWidth;
 end else begin
  ImageWidth:=1;
 end;
 if (Header.dwFlags and DDSD_HEIGHT)<>0 then begin
  ImageHeight:=Header.dwHeight;
 end else begin
  ImageHeight:=1;
 end;
 if (Header.dwFlags and DDSD_DEPTH)<>0 then begin
  ImageDepth:=Header.dwDepth;
 end else begin
  ImageDepth:=1;
 end;
 if (Header.dwFlags and DDSD_MIPMAPCOUNT)<>0 then begin
  ImageMipMaps:=Max(1,Header.dwMipMapCount);
 end else begin
  ImageMipMaps:=1;
 end;
 ImageFaces:=1;
 ImageArrayElements:=1;
 IsVolume:=false;
 if (Header.Caps.dwCaps1 and DDSCAPS_COMPLEX)<>0 then begin
  if (Header.Caps.dwCaps2 and DDSCAPS2_CUBEMAP)<>0 then begin
   if (Header.Caps.dwCaps2 and (DDSCAPS2_CUBEMAP_POSITIVEX or
                                DDSCAPS2_CUBEMAP_NEGATIVEX or
                                DDSCAPS2_CUBEMAP_POSITIVEY or
                                DDSCAPS2_CUBEMAP_NEGATIVEY or
                                DDSCAPS2_CUBEMAP_POSITIVEZ or
                                DDSCAPS2_CUBEMAP_NEGATIVEZ))=(DDSCAPS2_CUBEMAP_POSITIVEX or
                                                              DDSCAPS2_CUBEMAP_NEGATIVEX or
                                                              DDSCAPS2_CUBEMAP_POSITIVEY or
                                                              DDSCAPS2_CUBEMAP_NEGATIVEY or
                                                              DDSCAPS2_CUBEMAP_POSITIVEZ or
                                                              DDSCAPS2_CUBEMAP_NEGATIVEZ) then begin
    ImageFaces:=6;
   end else begin
    raise EpvVulkanTextureException.Create('Invalid DDS stream');
   end;
  end else if (Header.Caps.dwCaps2 and DDSCAPS2_VOLUME)<>0 then begin
   IsVolume:=true;
  end;
 end;
 ImageFormat:=VK_FORMAT_UNDEFINED;
 if (Header.dwFlags and DDSD_PIXELFORMAT)<>0 then begin
  if (Header.PixelFormat.dwFlags and DDPF_FOURCC)<>0 then begin
   case Header.PixelFormat.dwFourCC of
    D3DFMT_DXT1:begin
     ImageFormat:=VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
    end;
    D3DFMT_DXT2,D3DFMT_DXT3:begin
     ImageFormat:=VK_FORMAT_BC2_UNORM_BLOCK;
    end;
    D3DFMT_DXT4,D3DFMT_DXT5:begin
     ImageFormat:=VK_FORMAT_BC3_UNORM_BLOCK;
    end;
    D3DFMT_ATI1,D3DFMT_BC4U:begin
     ImageFormat:=VK_FORMAT_BC4_UNORM_BLOCK;
    end;
    D3DFMT_BC4S:begin
     ImageFormat:=VK_FORMAT_BC4_SNORM_BLOCK;
    end;
    D3DFMT_ATI2,D3DFMT_BC5U:begin
     ImageFormat:=VK_FORMAT_BC5_UNORM_BLOCK;
    end;
    D3DFMT_BC5S:begin
     ImageFormat:=VK_FORMAT_BC5_SNORM_BLOCK;
    end;
    D3DFMT_DX10:begin
     if aStream.Read(HeaderDX10,SizeOf(TDDSHeaderDX10))<>SizeOf(TDDSHeaderDX10) then begin
      raise EpvVulkanTextureException.Create('Invalid DDS stream');
     end;
     case HeaderDX10.dxgiFormat of
      DXGI_FORMAT_UNKNOWN:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_R32G32B32A32_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R32G32B32A32_UINT;
      end;
      DXGI_FORMAT_R32G32B32A32_FLOAT:begin
       ImageFormat:=VK_FORMAT_R32G32B32A32_SFLOAT;
      end;
      DXGI_FORMAT_R32G32B32A32_UINT:begin
       ImageFormat:=VK_FORMAT_R32G32B32A32_UINT;
      end;
      DXGI_FORMAT_R32G32B32A32_SINT:begin
       ImageFormat:=VK_FORMAT_R32G32B32A32_SINT;
      end;
      DXGI_FORMAT_R32G32B32_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R32G32B32_UINT;
      end;
      DXGI_FORMAT_R32G32B32_FLOAT:begin
       ImageFormat:=VK_FORMAT_R32G32B32_SFLOAT;
      end;
      DXGI_FORMAT_R32G32B32_UINT:begin
       ImageFormat:=VK_FORMAT_R32G32B32_UINT;
      end;
      DXGI_FORMAT_R32G32B32_SINT:begin
       ImageFormat:=VK_FORMAT_R32G32B32_SINT;
      end;
      DXGI_FORMAT_R16G16B16A16_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R16G16B16A16_UINT;
      end;
      DXGI_FORMAT_R16G16B16A16_FLOAT:begin
       ImageFormat:=VK_FORMAT_R16G16B16A16_SFLOAT;
      end;
      DXGI_FORMAT_R16G16B16A16_UNORM:begin
       ImageFormat:=VK_FORMAT_R16G16B16A16_UNORM;
      end;
      DXGI_FORMAT_R16G16B16A16_UINT:begin
       ImageFormat:=VK_FORMAT_R16G16B16A16_UINT;
      end;
      DXGI_FORMAT_R16G16B16A16_SNORM:begin
       ImageFormat:=VK_FORMAT_R16G16B16A16_SNORM;
      end;
      DXGI_FORMAT_R16G16B16A16_SINT:begin
       ImageFormat:=VK_FORMAT_R16G16B16A16_SINT;
      end;
      DXGI_FORMAT_R32G32_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R32G32_UINT;
      end;
      DXGI_FORMAT_R32G32_FLOAT:begin
       ImageFormat:=VK_FORMAT_R32G32_SFLOAT;
      end;
      DXGI_FORMAT_R32G32_UINT:begin
       ImageFormat:=VK_FORMAT_R32G32_UINT;
      end;
      DXGI_FORMAT_R32G32_SINT:begin
       ImageFormat:=VK_FORMAT_R32G32_SINT;
      end;
      DXGI_FORMAT_R32G8X24_TYPELESS:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_D32_FLOAT_S8X24_UINT:begin
       ImageFormat:=VK_FORMAT_D32_SFLOAT_S8_UINT;
      end;
      DXGI_FORMAT_R32_FLOAT_X8X24_TYPELESS:begin
       ImageFormat:=VK_FORMAT_D32_SFLOAT_S8_UINT;
      end;
      DXGI_FORMAT_X32_TYPELESS_G8X24_UINT:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_R10G10B10A2_TYPELESS:begin
       ImageFormat:=VK_FORMAT_A2R10G10B10_UINT_PACK32;
      end;
      DXGI_FORMAT_R10G10B10A2_UNORM:begin
       ImageFormat:=VK_FORMAT_A2R10G10B10_UNORM_PACK32;
      end;
      DXGI_FORMAT_R10G10B10A2_UINT:begin
       ImageFormat:=VK_FORMAT_A2R10G10B10_UINT_PACK32;
      end;
      DXGI_FORMAT_R11G11B10_FLOAT:begin
       ImageFormat:=VK_FORMAT_B10G11R11_UFLOAT_PACK32;
      end;
      DXGI_FORMAT_R8G8B8A8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R8G8B8A8_UINT;
      end;
      DXGI_FORMAT_R8G8B8A8_UNORM:begin
       ImageFormat:=VK_FORMAT_R8G8B8A8_UNORM;
      end;
      DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_R8G8B8A8_SRGB;
      end;
      DXGI_FORMAT_R8G8B8A8_UINT:begin
       ImageFormat:=VK_FORMAT_R8G8B8A8_UINT;
      end;
      DXGI_FORMAT_R8G8B8A8_SNORM:begin
       ImageFormat:=VK_FORMAT_R8G8B8A8_SNORM;
      end;
      DXGI_FORMAT_R8G8B8A8_SINT:begin
       ImageFormat:=VK_FORMAT_R8G8B8A8_SINT;
      end;
      DXGI_FORMAT_R16G16_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R16G16_UINT;
      end;
      DXGI_FORMAT_R16G16_FLOAT:begin
       ImageFormat:=VK_FORMAT_R16G16_SFLOAT;
      end;
      DXGI_FORMAT_R16G16_UNORM:begin
       ImageFormat:=VK_FORMAT_R16G16_UNORM;
      end;
      DXGI_FORMAT_R16G16_UINT:begin
       ImageFormat:=VK_FORMAT_R16G16_UINT;
      end;
      DXGI_FORMAT_R16G16_SNORM:begin
       ImageFormat:=VK_FORMAT_R16G16_SNORM;
      end;
      DXGI_FORMAT_R16G16_SINT:begin
       ImageFormat:=VK_FORMAT_R16G16_SINT;
      end;
      DXGI_FORMAT_R32_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R32_UINT;
      end;
      DXGI_FORMAT_D32_FLOAT:begin
       ImageFormat:=VK_FORMAT_D32_SFLOAT;
      end;
      DXGI_FORMAT_R32_FLOAT:begin
       ImageFormat:=VK_FORMAT_R32_SFLOAT;
      end;
      DXGI_FORMAT_R32_UINT:begin
       ImageFormat:=VK_FORMAT_R32_UINT;
      end;
      DXGI_FORMAT_R32_SINT:begin
       ImageFormat:=VK_FORMAT_R32_SINT;
      end;
      DXGI_FORMAT_R24G8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_D24_UNORM_S8_UINT:begin
       ImageFormat:=VK_FORMAT_D24_UNORM_S8_UINT;
      end;
      DXGI_FORMAT_R24_UNORM_X8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_X24_TYPELESS_G8_UINT:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_R8G8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R8G8_UINT;
      end;
      DXGI_FORMAT_R8G8_UNORM:begin
       ImageFormat:=VK_FORMAT_R8G8_UNORM;
      end;
      DXGI_FORMAT_R8G8_UINT:begin
       ImageFormat:=VK_FORMAT_R8G8_UINT;
      end;
      DXGI_FORMAT_R8G8_SNORM:begin
       ImageFormat:=VK_FORMAT_R8G8_SNORM;
      end;
      DXGI_FORMAT_R8G8_SINT:begin
       ImageFormat:=VK_FORMAT_R8G8_SINT;
      end;
      DXGI_FORMAT_R16_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R16_UINT;
      end;
      DXGI_FORMAT_R16_FLOAT:begin
       ImageFormat:=VK_FORMAT_R16_SFLOAT;
      end;
      DXGI_FORMAT_D16_UNORM:begin
       ImageFormat:=VK_FORMAT_D16_UNORM;
      end;
      DXGI_FORMAT_R16_UNORM:begin
       ImageFormat:=VK_FORMAT_R16_UNORM;
      end;
      DXGI_FORMAT_R16_UINT:begin
       ImageFormat:=VK_FORMAT_R16_UINT;
      end;
      DXGI_FORMAT_R16_SNORM:begin
       ImageFormat:=VK_FORMAT_R16_SNORM;
      end;
      DXGI_FORMAT_R16_SINT:begin
       ImageFormat:=VK_FORMAT_R16_SINT;
      end;
      DXGI_FORMAT_R8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_R8_UINT;
      end;
      DXGI_FORMAT_R8_UNORM:begin
       ImageFormat:=VK_FORMAT_R8_UNORM;
      end;
      DXGI_FORMAT_R8_UINT:begin
       ImageFormat:=VK_FORMAT_R8_UINT;
      end;
      DXGI_FORMAT_R8_SNORM:begin
       ImageFormat:=VK_FORMAT_R8_SNORM;
      end;
      DXGI_FORMAT_R8_SINT:begin
       ImageFormat:=VK_FORMAT_R8_SINT;
      end;
      DXGI_FORMAT_A8_UNORM:begin
       ImageFormat:=VK_FORMAT_R8_UNORM;
      end;
      DXGI_FORMAT_R1_UNORM:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_R9G9B9E5_SHAREDEXP:begin
       ImageFormat:=VK_FORMAT_E5B9G9R9_UFLOAT_PACK32;
      end;
      DXGI_FORMAT_R8G8_B8G8_UNORM:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_G8R8_G8B8_UNORM:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_BC1_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC1_UNORM:begin
       ImageFormat:=VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC1_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_BC1_RGBA_SRGB_BLOCK;
      end;
      DXGI_FORMAT_BC2_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC1_RGBA_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC2_UNORM:begin
       ImageFormat:=VK_FORMAT_BC2_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC2_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_BC2_SRGB_BLOCK;
      end;
      DXGI_FORMAT_BC3_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC2_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC3_UNORM:begin
       ImageFormat:=VK_FORMAT_BC3_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC3_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_BC3_SRGB_BLOCK;
      end;
      DXGI_FORMAT_BC4_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC4_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC4_UNORM:begin
       ImageFormat:=VK_FORMAT_BC4_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC4_SNORM:begin
       ImageFormat:=VK_FORMAT_BC4_SNORM_BLOCK;
      end;
      DXGI_FORMAT_BC5_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC5_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC5_UNORM:begin
       ImageFormat:=VK_FORMAT_BC5_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC5_SNORM:begin
       ImageFormat:=VK_FORMAT_BC5_SNORM_BLOCK;
      end;
      DXGI_FORMAT_B5G6R5_UNORM:begin
       ImageFormat:=VK_FORMAT_B5G6R5_UNORM_PACK16;
      end;
      DXGI_FORMAT_B5G5R5A1_UNORM:begin
       ImageFormat:=VK_FORMAT_B5G5R5A1_UNORM_PACK16;
      end;
      DXGI_FORMAT_B8G8R8A8_UNORM:begin
       ImageFormat:=VK_FORMAT_B8G8R8A8_UNORM;
      end;
      DXGI_FORMAT_B8G8R8X8_UNORM:begin
       ImageFormat:=VK_FORMAT_B8G8R8_UNORM;
      end;
      DXGI_FORMAT_R10G10B10_XR_BIAS_A2_UNORM:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_B8G8R8A8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_B8G8R8A8_UINT;
      end;
      DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_B8G8R8A8_SRGB;
      end;
      DXGI_FORMAT_B8G8R8X8_TYPELESS:begin
       ImageFormat:=VK_FORMAT_B8G8R8_UINT;
      end;
      DXGI_FORMAT_B8G8R8X8_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_B8G8R8_SRGB;
      end;
      DXGI_FORMAT_BC6H_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC6H_UFLOAT_BLOCK;
      end;
      DXGI_FORMAT_BC6H_UF16:begin
       ImageFormat:=VK_FORMAT_BC6H_UFLOAT_BLOCK;
      end;
      DXGI_FORMAT_BC6H_SF16:begin
       ImageFormat:=VK_FORMAT_BC6H_SFLOAT_BLOCK;
      end;
      DXGI_FORMAT_BC7_TYPELESS:begin
       ImageFormat:=VK_FORMAT_BC7_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC7_UNORM:begin
       ImageFormat:=VK_FORMAT_BC7_UNORM_BLOCK;
      end;
      DXGI_FORMAT_BC7_UNORM_SRGB:begin
       ImageFormat:=VK_FORMAT_BC7_SRGB_BLOCK;
      end;
      DXGI_FORMAT_AYUV:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_Y410:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_Y416:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_NV12:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_P010:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_P016:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_420_OPAQUE:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_YUY2:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_Y210:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_Y216:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_NV11:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_AI44:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_IA44:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;                                                
      DXGI_FORMAT_P8:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_A8P8:begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
      DXGI_FORMAT_B4G4R4A4_UNORM:begin
       ImageFormat:=VK_FORMAT_B4G4R4A4_UNORM_PACK16;
      end;
      else begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
     end;
     ImageArrayElements:=HeaderDX10.ArraySize;
    end;
   end;
  end else begin
   case Header.PixelFormat.dwRGBBitCount of
    8:begin
     if (Header.PixelFormat.dwFlags and DDPF_INDEXED)<>0 then begin
      ImageFormat:=VK_FORMAT_UNDEFINED;
     end else begin
      if ((Header.PixelFormat.dwFlags and DDPF_LUMINANCE)<>0) or
                  (Header.PixelFormat.dwRBitMask=$000000ff) and
                  (Header.PixelFormat.dwGBitMask=$00000000) and
                  (Header.PixelFormat.dwBBitMask=$00000000) and
                  (Header.PixelFormat.dwABitMask=$00000000) then begin
       ImageFormat:=VK_FORMAT_R8_UNORM;
      end else if ((Header.PixelFormat.dwFlags and DDPF_ALPHA)<>0) or
                  (Header.PixelFormat.dwRBitMask=$000000ff) and
                  (Header.PixelFormat.dwGBitMask=$00000000) and
                  (Header.PixelFormat.dwBBitMask=$00000000) and
                  (Header.PixelFormat.dwABitMask=$00000000) then begin
       ImageFormat:=VK_FORMAT_R8_UNORM;
      end else begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
      end;
     end;
    end;
    16:begin
     if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
        (Header.PixelFormat.dwRBitMask=$0000f800) and
        (Header.PixelFormat.dwGBitMask=$000007e0) and
        (Header.PixelFormat.dwBBitMask=$0000001f) and
        (Header.PixelFormat.dwABitMask=$00000000) then begin
      ImageFormat:=VK_FORMAT_B5G6R5_UNORM_PACK16;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$00007c00) and
                 (Header.PixelFormat.dwGBitMask=$000003e0) and
                 (Header.PixelFormat.dwBBitMask=$0000001f) and
                 (Header.PixelFormat.dwABitMask=$00008000) then begin
      ImageFormat:=VK_FORMAT_B5G5R5A1_UNORM_PACK16;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$00000f00) and
                 (Header.PixelFormat.dwGBitMask=$000000f0) and
                 (Header.PixelFormat.dwBBitMask=$0000000f) and
                 (Header.PixelFormat.dwABitMask=$0000f000) then begin
      ImageFormat:=VK_FORMAT_B4G4R4A4_UNORM_PACK16;
     end else if (Header.PixelFormat.dwRBitMask=$000000ff) and
                 (Header.PixelFormat.dwGBitMask=$00000000) and
                 (Header.PixelFormat.dwBBitMask=$00000000) and
                 (Header.PixelFormat.dwABitMask=$0000ff00) then begin
       ImageFormat:=VK_FORMAT_UNDEFINED;
     end else if (Header.PixelFormat.dwRBitMask=$0000ffff) or
                 (Header.PixelFormat.dwGBitMask=$0000ffff) or
                 (Header.PixelFormat.dwBBitMask=$0000ffff) or
                 (Header.PixelFormat.dwABitMask=$0000ffff) then begin
      ImageFormat:=VK_FORMAT_R16_UNORM;
      end else if ((Header.PixelFormat.dwFlags and DDPF_LUMINANCE)<>0) or
                  (Header.PixelFormat.dwRBitMask=$0000ffff) and
                  (Header.PixelFormat.dwGBitMask=$00000000) and
                  (Header.PixelFormat.dwBBitMask=$00000000) and
                  (Header.PixelFormat.dwABitMask=$00000000) then begin
       ImageFormat:=VK_FORMAT_R16_UNORM;
      end else if ((Header.PixelFormat.dwFlags and DDPF_LUMINANCE)<>0) or
                  (Header.PixelFormat.dwRBitMask=$000000ff) and
                  (Header.PixelFormat.dwGBitMask=$00000000) and
                  (Header.PixelFormat.dwBBitMask=$00000000) and
                  (Header.PixelFormat.dwABitMask=$0000ff00) then begin
       ImageFormat:=VK_FORMAT_R8G8_UNORM;
     end;
    end;
    24:begin
     if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
        (Header.PixelFormat.dwRBitMask=$00ff0000) and
        (Header.PixelFormat.dwGBitMask=$0000ff00) and
        (Header.PixelFormat.dwBBitMask=$000000ff) then begin
      ImageFormat:=VK_FORMAT_B8G8R8_UNORM;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$000000ff) and
                 (Header.PixelFormat.dwGBitMask=$0000ff00) and
                 (Header.PixelFormat.dwBBitMask=$00ff0000) then begin
      ImageFormat:=VK_FORMAT_R8G8B8_UNORM;
     end;
    end;
    32:begin
     if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
        (Header.PixelFormat.dwRBitMask=$00ff0000) and
        (Header.PixelFormat.dwGBitMask=$0000ff00) and
        (Header.PixelFormat.dwBBitMask=$000000ff) and
        (Header.PixelFormat.dwABitMask=$ff000000) then begin
      ImageFormat:=VK_FORMAT_B8G8R8A8_UNORM;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$000000ff) and
                 (Header.PixelFormat.dwGBitMask=$0000ff00) and
                 (Header.PixelFormat.dwBBitMask=$00ff0000) and
                 (Header.PixelFormat.dwABitMask=$ff000000) then begin
      ImageFormat:=VK_FORMAT_R8G8B8A8_UNORM;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$000003ff) and
                 (Header.PixelFormat.dwGBitMask=$000ffc00) and
                 (Header.PixelFormat.dwBBitMask=$3ff00000) and
                 (Header.PixelFormat.dwABitMask=$c0000000) then begin
      ImageFormat:=VK_FORMAT_A2R10G10B10_UNORM_PACK32;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$0000ffff) and
                 (Header.PixelFormat.dwGBitMask=$fff00000) and
                 (Header.PixelFormat.dwBBitMask=$00000000) and
                 (Header.PixelFormat.dwABitMask=$00000000) then begin
      ImageFormat:=VK_FORMAT_R16G16_UNORM;
     end else if ((Header.PixelFormat.dwFlags and DDPF_RGB)<>0) and
                 (Header.PixelFormat.dwRBitMask=$ffffffff) and
                 (Header.PixelFormat.dwGBitMask=$00000000) and
                 (Header.PixelFormat.dwBBitMask=$00000000) and
                 (Header.PixelFormat.dwABitMask=$00000000) then begin
      ImageFormat:=VK_FORMAT_R32_SFLOAT;
     end;
    end;
   end;
  end;
 end;
 if ImageFormat=VK_FORMAT_UNDEFINED then begin
  raise EpvVulkanTextureException.Create('Invalid DDS stream');
 end;
 if (ImageDepth>1) and not IsVolume then begin
  raise EpvVulkanTextureException.Create('Invalid DDS stream');
 end;
 DataSize:=aStream.Size-aStream.Position;
 GetMem(Data,DataSize);
 try
  if aStream.Read(Data^,DataSize)<>DataSize then begin
   raise EpvVulkanTextureException.Create('Stream read error');
  end;
  CreateFromMemory(aDevice,
                   aGraphicsQueue,
                   aGraphicsCommandBuffer,
                   aGraphicsFence,
                   aTransferQueue,
                   aTransferCommandBuffer,
                   aTransferFence,
                   ImageFormat,
                   VK_SAMPLE_COUNT_1_BIT,
                   Max(1,ImageWidth),
                   Max(1,ImageHeight),
                   Max(1,ImageDepth),
                   IfThen(ImageArrayElements=1,0,ImageArrayElements),
                   ImageFaces,
                   ImageMipMaps,
                   [vtufTransferDst,vtufSampled],
                   Data,
                   DataSize,
                   false,
                   false,
                   1,
                   true);
 finally
  FreeMem(Data);
 end;     
end;

constructor TpvVulkanTexture.CreateFromHDR(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aStream:TStream;
                                           const aMipMaps:boolean;
                                           const aSRGB:boolean);
const RGBE_DATA_RED=0;
      RGBE_DATA_GREEN=1;
      RGBE_DATA_BLUE=2;
      RGBE_DATA_SIZE=3;
 procedure rgbe2float(const r,g,b,e:TpvUInt8;out red,green,blue,alpha:TpvFloat);
 var f:TpvFloat;
 begin
  if e<>0 then begin
   f:=ldexp(1.0,e-(128+8));
 //f:=power(2.0,e-(128+8));
   red:=r*f;
   green:=g*f;
   blue:=b*f;
   alpha:=1.0;
  end else begin
   red:=0.0;
   green:=0.0;
   blue:=0.0;
   alpha:=0.0;
  end;
 end;
 function LoadHDRImage(var ImageData:TpvPointer;var ImageWidth,ImageHeight:TpvInt32):boolean;
 label NonRLE,DoFail;
 var i,j,k,CountPixels,y,x:TpvInt32;
     programtype,line:shortstring;
     gamma,exposure,r,g,b,a:TpvFloat;
     scanlinebuffer:array of array[0..3] of TpvUInt8;
     c:TpvVulkanRawByteChar;
     OK:longbool;
     buf:array[0..3] of TpvVulkanRawByteChar;
     rgbe:array[0..3] of TpvUInt8;
     Len,Val:TpvUInt8;
     p:PVkFloat;
 begin
  result:=false;
  scanlinebuffer:=nil;
  ImageData:=nil;
  if aStream.Size>16 then begin
   buf[0]:=#0;
   buf[1]:=#0;
   aStream.Read(buf,2*SizeOf(AnsiChar));
   if (buf[0]<>'#') or (buf[1]<>'?') then begin
    exit;
   end;
   programtype:='';
   gamma:=1.0;
   exposure:=1.0;
   begin
    i:=0;
    while aStream.Read(c,SizeOf(AnsiChar))=SizeOf(AnsiChar) do begin
     if c in [#1..#9,#11..#12,#14..#32] then begin
      break;
     end else if i<255 then begin
      inc(i);
      programtype[i]:=c;
     end;
    end;
    programtype[0]:=TpvVulkanRawByteChar(TpvUInt8(i));
    while aStream.Read(c,SizeOf(AnsiChar))=SizeOf(AnsiChar) do begin
     if c in [#0,#10,#13] then begin
      break;
     end;
    end;
   end;
   if length(programtype)>0 then begin
   end;
   OK:=false;
   while aStream.Position<aStream.Size do begin
    line:='';
    i:=0;
    while aStream.Read(c,SizeOf(AnsiChar))=SizeOf(AnsiChar) do begin
     if c in [#0,#10,#13] then begin
      break;
     end else if i<255 then begin
      inc(i);
      line[i]:=c;
     end;
    end;
    line[0]:=TpvVulkanRawByteChar(TpvUInt8(i));
    line:=ShortString(Trim(String(line)));
    if line='FORMAT=32-bit_rle_rgbe' then begin
     OK:=true;
     break;
    end else if Pos('GAMMA=',String(line))=1 then begin
     Delete(line,1,6);
     OK:=false;
     gamma:=0;
     System.Val(String(line),gamma,k);
     if k>0 then begin
      gamma:=1.0;
     end;
     OK:=false;
    end else if Pos('EXPOSURE=',String(line))=1 then begin
     Delete(line,1,9);
     System.Val(String(line),exposure,k);
     if k>0 then begin
      exposure:=1.0;
     end;
     OK:=false;
    end;
   end;
   if not OK then begin
    exit;
   end;
   OK:=false;
   while aStream.Position<aStream.Size do begin
    line:='';
    i:=0;
    while aStream.Read(c,SizeOf(AnsiChar))=SizeOf(AnsiChar) do begin
     if c in [#0,#10,#13] then begin
      break;
     end else if i<255 then begin
      inc(i);
      line[i]:=c;
     end;
    end;
    line[0]:=TpvVulkanRawByteChar(TpvUInt8(i));
    line:=ShortString(Trim(String(line)));
    if (pos('-Y',String(line))=1) and (pos('+X',String(line))>2) then begin
     Delete(line,1,2);
     line:=ShortString(Trim(String(line)));
     ImageWidth:=0;
     i:=0;
     while ((i+1)<=length(line)) and (line[i+1] in ['0'..'9']) do begin
      inc(i);
      ImageWidth:=(ImageWidth*10)+(TpvUInt8(TpvVulkanRawByteChar(line[i]))-TpvUInt8(TpvVulkanRawByteChar('0')));
     end;
     Delete(line,1,i);
     line:=ShortString(Trim(String(line)));
     if pos('-X',String(line))=1 then begin
      Delete(line,1,2);
      line:=ShortString(Trim(String(line)));
      ImageHeight:=0;
      i:=0;
      while ((i+1)<=length(line)) and (line[i+1] in ['0'..'9']) do begin
       inc(i);
       ImageHeight:=(ImageHeight*10)+(TpvUInt8(TpvVulkanRawByteChar(line[i]))-TpvUInt8(TpvVulkanRawByteChar('0')));
      end;
      OK:=true;
     end;
     break;
    end;
   end;
   if not OK then begin
    exit;
   end;
   begin
    CountPixels:=ImageWidth*ImageHeight;
    GetMem(ImageData,CountPixels*(SizeOf(TpvFloat)*4));
    p:=ImageData;
    if (ImageWidth<8) or (ImageWidth>$7fff) then begin
     NonRLE:
     while (CountPixels>0) and (aStream.Read(rgbe,SizeOf(TpvUInt8)*4)=(SizeOf(TpvUInt8)*4)) do begin
      dec(CountPixels);
      rgbe2float(rgbe[0],rgbe[1],rgbe[2],rgbe[3],r,g,b,a);
      p^:=r;
      inc(p);
      p^:=g;
      inc(p);
      p^:=b;
      inc(p);
      p^:=a;
      inc(p);
     end;
    end else begin
     y:=ImageHeight;
     while (CountPixels>0) and (y>0) do begin
      dec(y);
      if aStream.Read(rgbe,SizeOf(TpvUInt8)*4)=(SizeOf(TpvUInt8)*4) then begin
       if (rgbe[0]<>2) or (rgbe[1]<>2) or ((rgbe[2] and $80)<>0) then begin
        aStream.Seek(-(SizeOf(TpvUInt8)*4),soCurrent);
        goto NonRLE;
       end else begin
        if TpvInt32((TpvInt32(rgbe[2]) shl 8) or TpvInt32(rgbe[3]))<>ImageWidth then begin
         goto DoFail;
        end;
        if length(scanlinebuffer)<>ImageWidth then begin
         SetLength(scanlinebuffer,ImageWidth);
        end;
        for i:=0 to 3 do begin
         x:=0;
         while x<ImageWidth do begin
          if aStream.Read(Len,SizeOf(TpvUInt8))=SizeOf(TpvUInt8) then begin
           if Len>128 then begin
            k:=Len-128;
            if (x+k)>ImageWidth then begin
             goto DoFail;
            end;
            if aStream.Read(Val,SizeOf(TpvUInt8))=SizeOf(TpvUInt8) then begin
             for j:=1 to k do begin
              scanlinebuffer[x,i]:=Val;
              inc(x);
             end;
            end else begin
             goto DoFail;
            end;
           end else begin
            k:=Len;
            if (x+k)>ImageWidth then begin
             goto DoFail;
            end;
            for j:=1 to k do begin
             if aStream.Read(scanlinebuffer[x,i],SizeOf(TpvUInt8))<>SizeOf(TpvUInt8) then begin
              goto DoFail;
             end;
             inc(x);
            end;
           end;
          end else begin
           goto DoFail;
          end;
         end;
         for x:=0 to ImageWidth-1 do begin
          rgbe2float(scanlinebuffer[x,0],scanlinebuffer[x,1],scanlinebuffer[x,2],scanlinebuffer[x,3],r,g,b,a);
          p^:=r;
          inc(p);
          p^:=g;
          inc(p);
          p^:=b;
          inc(p);
          p^:=a;
          inc(p);
          dec(CountPixels);
         end;
        end;
       end;
      end else begin
       break;
      end;
     end;
    end;
    result:=CountPixels=0;
   end;
   DoFail:
   if result then begin
    if (abs(1.0-gamma)>1e-12) or (abs(1.0-exposure)>1e-12) then begin
     CountPixels:=ImageWidth*ImageHeight;
     p:=ImageData;
     while CountPixels>0 do begin
      dec(CountPixels);
      p^:=power(p^,gamma)*exposure;
      inc(p);
      p^:=power(p^,gamma)*exposure;
      inc(p);
      p^:=power(p^,gamma)*exposure;
      inc(p,2);
     end;
    end;
   end else begin
    FreeMem(ImageData);
    ImageData:=nil;
   end;
   SetLength(scanlinebuffer,0);
  end;
 end;
var ImageData:TpvPointer;
    ImageWidth,ImageHeight:TpvInt32;
begin
 ImageData:=nil;
 ImageWidth:=0;
 ImageHeight:=0;
 try
  if LoadHDRImage(ImageData,ImageWidth,ImageHeight) then begin
   CreateFromMemory(aDevice,
                    aGraphicsQueue,
                    aGraphicsCommandBuffer,
                    aGraphicsFence,
                    aTransferQueue,
                    aTransferCommandBuffer,
                    aTransferFence,
                    VK_FORMAT_R32G32B32A32_SFLOAT,
                    VK_SAMPLE_COUNT_1_BIT,
                    Max(1,ImageWidth),
                    Max(1,ImageHeight),
                    0,
                    0,
                    1,
                    MipMapLevels[aMipMaps],
                    [vtufTransferDst,vtufSampled],
                    ImageData,
                    ImageWidth*ImageHeight*SizeOf(TpvFloat)*4,
                    false,
                    false,
                    1,
                    true);
  end else begin
   raise EpvVulkanTextureException.Create('Invalid HDR stream');
  end;
 finally
  if assigned(ImageData) then begin
   FreeMem(ImageData);
  end;
 end;
end;

constructor TpvVulkanTexture.CreateFromTGA(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aStream:TStream;
                                           const aMipMaps:boolean;
                                           const aSRGB:boolean);
var Data,ImageData:TpvPointer;
    DataSize,ImageWidth,ImageHeight:TpvInt32;
begin
 DataSize:=aStream.Size;
 GetMem(Data,DataSize);
 try
  if aStream.Read(Data^,DataSize)<>DataSize then begin
   raise EpvVulkanTextureException.Create('Invalid TGA stream');
  end;
  ImageData:=nil;
  ImageWidth:=0;
  ImageHeight:=0;
  try
   if LoadTGAImage(Data,DataSize,ImageData,ImageWidth,ImageHeight,false) then begin
    CreateFromMemory(aDevice,
                     aGraphicsQueue,
                     aGraphicsCommandBuffer,
                     aGraphicsFence,
                     aTransferQueue,
                     aTransferCommandBuffer,
                     aTransferFence,
                     TVkFormat(TVkInt32(IfThen(aSRGB,TVkInt32(VK_FORMAT_R8G8B8A8_SRGB),TVkInt32(VK_FORMAT_R8G8B8A8_UNORM)))),
                     VK_SAMPLE_COUNT_1_BIT,
                     Max(1,ImageWidth),
                     Max(1,ImageHeight),
                     0,
                     0,
                     1,
                     MipMapLevels[aMipMaps],
                     [vtufTransferDst,vtufSampled],
                     ImageData,
                     ImageWidth*ImageHeight*SizeOf(TpvUInt8)*4,
                     false,
                     false,
                     1,
                     true);
   end else begin
    raise EpvVulkanTextureException.Create('Invalid TGA stream');
   end;
  finally
   if assigned(ImageData) then begin
    FreeMem(ImageData);
   end;
  end;
 finally
  FreeMem(Data);
 end;
end;

constructor TpvVulkanTexture.CreateFromPNG(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aStream:TStream;
                                           const aMipMaps:boolean;
                                           const aSRGB:boolean);
var Data,ImageData:TpvPointer;
    DataSize,ImageWidth,ImageHeight,VulkanBytesPerPixel,x,y,Index:TpvInt32;
    PNGPixelFormat:TpvPNGPixelFormat;
    VulkanPixelFormat:TVkFormat;
    p:PVkUInt16;
    v:TVkFloat;
begin
 DataSize:=aStream.Size;
 GetMem(Data,DataSize);
 try
  if aStream.Read(Data^,DataSize)<>DataSize then begin
   raise EpvVulkanTextureException.Create('Invalid PNG stream');
  end;
  ImageData:=nil;
  ImageWidth:=0;
  ImageHeight:=0;
  try
   PNGPixelFormat:=pvppfUnknown;
   if LoadPNGImage(Data,DataSize,ImageData,ImageWidth,ImageHeight,false,PNGPixelFormat) then begin
    case PNGPixelFormat of
     pvppfR8G8B8A8:begin
      VulkanPixelFormat:=TVkFormat(TVkInt32(IfThen(aSRGB,TVkInt32(VK_FORMAT_R8G8B8A8_SRGB),TVkInt32(VK_FORMAT_R8G8B8A8_UNORM))));
      VulkanBytesPerPixel:=4;
     end;
     pvppfR16G16B16A16:begin
      VulkanPixelFormat:=VK_FORMAT_R16G16B16A16_UNORM;
      VulkanBytesPerPixel:=8;
      if aSRGB then begin
       // Because VK_FORMAT_R16G16B16A16_SRGB doesn't exist (yet), . . .
       p:=@ImageData;
       Index:=0;
       for y:=1 to ImageHeight do begin
        for x:=1 to ImageWidth do begin
         if (Index and 3)<>3 then begin
          // Only convert the RGB color channels, but not the alpha channel
          v:=p^/65535.0;
          if v<0.04045 then begin
           v:=v/12.92;
          end else begin
           v:=Power((v+0.055)/1.055,2.4);
          end;
          p^:=Min(Max(Round(v*65535.0),0),65535);
         end;
         inc(p);
         inc(Index);
        end;
       end;
      end;
     end;
     else begin
      VulkanPixelFormat:=TVkFormat(TVkInt32(IfThen(aSRGB,TVkInt32(VK_FORMAT_R8G8B8A8_SRGB),TVkInt32(VK_FORMAT_R8G8B8A8_UNORM))));
      VulkanBytesPerPixel:=4;
      raise EpvVulkanTextureException.Create('Invalid PNG stream');
     end;
    end;
    CreateFromMemory(aDevice,
                     aGraphicsQueue,
                     aGraphicsCommandBuffer,
                     aGraphicsFence,
                     aTransferQueue,
                     aTransferCommandBuffer,
                     aTransferFence,
                     VulkanPixelFormat,
                     VK_SAMPLE_COUNT_1_BIT,
                     Max(1,ImageWidth),
                     Max(1,ImageHeight),
                     0,
                     0,
                     1,
                     MipMapLevels[aMipMaps],
                     [vtufTransferDst,vtufSampled],
                     ImageData,
                     ImageWidth*ImageHeight*VulkanBytesPerPixel,
                     false,
                     false,
                     1,
                     true);
   end else begin
    raise EpvVulkanTextureException.Create('Invalid PNG stream');
   end;
  finally
   if assigned(ImageData) then begin
    FreeMem(ImageData);
   end;
  end;
 finally
  FreeMem(Data);
 end;
end;

constructor TpvVulkanTexture.CreateFromJPEG(const aDevice:TpvVulkanDevice;
                                            const aGraphicsQueue:TpvVulkanQueue;
                                            const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                            const aGraphicsFence:TpvVulkanFence;
                                            const aTransferQueue:TpvVulkanQueue;
                                            const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                            const aTransferFence:TpvVulkanFence;
                                            const aStream:TStream;
                                            const aMipMaps:boolean;
                                            const aSRGB:boolean);
var Data,ImageData:TpvPointer;
    DataSize,ImageWidth,ImageHeight:TpvInt32;
begin
 DataSize:=aStream.Size;
 GetMem(Data,DataSize);
 try
  if aStream.Read(Data^,DataSize)<>DataSize then begin
   raise EpvVulkanTextureException.Create('Invalid JPEG stream');
  end;
  ImageData:=nil;
  ImageWidth:=0;
  ImageHeight:=0;
  try
   if LoadJPEGImage(Data,DataSize,ImageData,ImageWidth,ImageHeight,false) then begin
    CreateFromMemory(aDevice,
                     aGraphicsQueue,
                     aGraphicsCommandBuffer,
                     aGraphicsFence,
                     aTransferQueue,
                     aTransferCommandBuffer,
                     aTransferFence,
                     TVkFormat(TVkInt32(IfThen(aSRGB,TVkInt32(VK_FORMAT_R8G8B8A8_SRGB),TVkInt32(VK_FORMAT_R8G8B8A8_UNORM)))),
                     VK_SAMPLE_COUNT_1_BIT,
                     Max(1,ImageWidth),
                     Max(1,ImageHeight),
                     0,
                     0,
                     1,
                     MipMapLevels[aMipMaps],
                     [vtufTransferDst,vtufSampled],
                     ImageData,
                     ImageWidth*ImageHeight*SizeOf(TpvUInt8)*4,
                     false,
                     false,
                     1,
                     true);
   end else begin
    raise EpvVulkanTextureException.Create('Invalid JPEG stream');
   end;
  finally
   if assigned(ImageData) then begin
    FreeMem(ImageData);
   end;
  end;
 finally
  FreeMem(Data);
 end;
end;

constructor TpvVulkanTexture.CreateFromBMP(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aStream:TStream;
                                           const aMipMaps:boolean;
                                           const aSRGB:boolean);
var Data,ImageData:TpvPointer;
    DataSize,ImageWidth,ImageHeight:TpvInt32;
begin
 DataSize:=aStream.Size;
 GetMem(Data,DataSize);
 try
  if aStream.Read(Data^,DataSize)<>DataSize then begin
   raise EpvVulkanTextureException.Create('Invalid JPEG stream');
  end;
  ImageData:=nil;
  ImageWidth:=0;
  ImageHeight:=0;
  try
   if LoadBMPImage(Data,DataSize,ImageData,ImageWidth,ImageHeight,false) then begin
    CreateFromMemory(aDevice,
                     aGraphicsQueue,
                     aGraphicsCommandBuffer,
                     aGraphicsFence,
                     aTransferQueue,
                     aTransferCommandBuffer,
                     aTransferFence,
                     TVkFormat(TVkInt32(IfThen(aSRGB,TVkInt32(VK_FORMAT_R8G8B8A8_SRGB),TVkInt32(VK_FORMAT_R8G8B8A8_UNORM)))),
                     VK_SAMPLE_COUNT_1_BIT,
                     Max(1,ImageWidth),
                     Max(1,ImageHeight),
                     0,
                     0,
                     1,
                     MipMapLevels[aMipMaps],
                     [vtufTransferDst,vtufSampled],
                     ImageData,
                     ImageWidth*ImageHeight*SizeOf(TpvUInt8)*4,
                     false,
                     false,
                     1,
                     true);
   end else begin
    raise EpvVulkanTextureException.Create('Invalid BMP stream');
   end;
  finally
   if assigned(ImageData) then begin
    FreeMem(ImageData);
   end;
  end;
 finally
  FreeMem(Data);
 end;
end;

constructor TpvVulkanTexture.CreateFromImage(const aDevice:TpvVulkanDevice;
                                             const aGraphicsQueue:TpvVulkanQueue;
                                             const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                             const aGraphicsFence:TpvVulkanFence;
                                             const aTransferQueue:TpvVulkanQueue;
                                             const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                             const aTransferFence:TpvVulkanFence;
                                             const aStream:TStream;
                                             const aMipMaps:boolean;
                                             const aSRGB:boolean);
const DDS_MAGIC=$20534444;
      DDSD_CAPS=$00000001;
      DDSD_PIXELFORMAT=$00001000;
type PFirstBytes=^TFirstBytes;
     TFirstBytes=array[0..63] of TpvUInt8;
     PDDSHeader=^TDDSHeader;
     TDDSHeader=packed record
      dwMagic:TpvUInt32;
      dwSize:TpvUInt32;
      dwFlags:TpvUInt32;
      dwHeight:TpvUInt32;
      dwWidth:TpvUInt32;
      dwPitchOrLinearSize:TpvUInt32;
      dwDepth:TpvUInt32;
      dwMipMapCount:TpvUInt32;
     end;
var FirstBytes:TFirstBytes;
begin
 aStream.Seek(0,soBeginning);
 FillChar(FirstBytes,SizeOf(FirstBytes),#0);
 aStream.ReadBuffer(FirstBytes,Min(SizeOf(FirstBytes),aStream.Size));
 aStream.Seek(0,soBeginning);
 if (FirstBytes[0]=$ab) and (FirstBytes[1]=$4b) and (FirstBytes[2]=$54) and (FirstBytes[3]=$58) and (FirstBytes[4]=$20) and (FirstBytes[5]=$31) and (FirstBytes[6]=$31) and (FirstBytes[7]=$bb) and (FirstBytes[8]=$0d) and (FirstBytes[9]=$0a) and (FirstBytes[10]=$1a) and (FirstBytes[11]=$0a) then begin
  CreateFromKTX(aDevice,
                aGraphicsQueue,
                aGraphicsCommandBuffer,
                aGraphicsFence,
                aTransferQueue,
                aTransferCommandBuffer,
                aTransferFence,
                aStream);
 end else if (FirstBytes[0]=$89) and (FirstBytes[1]=$50) and (FirstBytes[2]=$4e) and (FirstBytes[3]=$47) and (FirstBytes[4]=$0d) and (FirstBytes[5]=$0a) and (FirstBytes[6]=$1a) and (FirstBytes[7]=$0a) then begin
  CreateFromPNG(aDevice,
                aGraphicsQueue,
                aGraphicsCommandBuffer,
                aGraphicsFence,
                aTransferQueue,
                aTransferCommandBuffer,
                aTransferFence,
                aStream,
                aMipMaps,
                aSRGB);
 end else if ((PDDSHeader(TpvPointer(@FirstBytes))^.dwMagic=DDS_MAGIC) and (PDDSHeader(TpvPointer(@FirstBytes))^.dwSize=124) and not (((PDDSHeader(TpvPointer(@FirstBytes))^.dwFlags and DDSD_PIXELFORMAT)=0) or ((PDDSHeader(TpvPointer(@FirstBytes))^.dwFlags and DDSD_CAPS)=0))) then begin
  CreateFromDDS(aDevice,
                aGraphicsQueue,
                aGraphicsCommandBuffer,
                aGraphicsFence,
                aTransferQueue,
                aTransferCommandBuffer,
                aTransferFence,
                aStream);
 end else if (FirstBytes[0]=TpvUInt8(AnsiChar('B'))) and (FirstBytes[1]=TpvUInt8(AnsiChar('M'))) then begin
  CreateFromBMP(aDevice,
                aGraphicsQueue,
                aGraphicsCommandBuffer,
                aGraphicsFence,
                aTransferQueue,
                aTransferCommandBuffer,
                aTransferFence,
                aStream,
                aMipMaps,
                aSRGB);
 end else if (FirstBytes[0]=TpvUInt8(AnsiChar('#'))) and (FirstBytes[1]=TpvUInt8(AnsiChar('?'))) then begin
  CreateFromHDR(aDevice,
                aGraphicsQueue,
                aGraphicsCommandBuffer,
                aGraphicsFence,
                aTransferQueue,
                aTransferCommandBuffer,
                aTransferFence,
                aStream,
                aMipMaps,
                aSRGB);
 end else if ((FirstBytes[0] xor $ff) or (FirstBytes[1] xor $d8))=0 then begin
  CreateFromJPEG(aDevice,
                 aGraphicsQueue,
                 aGraphicsCommandBuffer,
                 aGraphicsFence,
                 aTransferQueue,
                 aTransferCommandBuffer,
                 aTransferFence,
                 aStream,
                 aMipMaps,
                 aSRGB);
 end else begin
  CreateFromTGA(aDevice,
                aGraphicsQueue,
                aGraphicsCommandBuffer,
                aGraphicsFence,
                aTransferQueue,
                aTransferCommandBuffer,
                aTransferFence,
                aStream,
                aMipMaps,
                aSRGB);
 end;
end;

constructor TpvVulkanTexture.CreateDefault(const aDevice:TpvVulkanDevice;
                                           const aGraphicsQueue:TpvVulkanQueue;
                                           const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                           const aGraphicsFence:TpvVulkanFence;
                                           const aTransferQueue:TpvVulkanQueue;
                                           const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                           const aTransferFence:TpvVulkanFence;
                                           const aDefaultType:TpvVulkanTextureDefaultType;
                                           const aWidth:TpvInt32;
                                           const aHeight:TpvInt32;
                                           const aDepth:TpvInt32;
                                           const aCountArrayLayers:TpvInt32;
                                           const aCountFaces:TpvInt32;
                                           const aMipmaps:boolean;
                                           const aBorder:boolean;
                                           const aSRGB:boolean);
const TexelSize=4;
      BlockShift=5;
      BlockSize=1 shl BlockShift;
      BlockMask=BlockSize-1;
      Radius=10;
      Colors:array[0..3,0..3] of TpvUInt8=
       (($ff,$00,$00,$ff),
        ($00,$ff,$00,$ff),
        ($00,$00,$ff,$ff),
        ($ff,$ff,$00,$ff));
var LayerSize,DataSize,LayerIndex,x,y,Offset,lx,ly,rx,ry,cx,cy,m,Index,dx,dy,ds,Scale,CountMipMaps:TpvInt32;
    Data:TVkUInt8Array;
begin

 LayerSize:=aWidth*aHeight*TexelSize;
 DataSize:=LayerSize*Max(1,aDepth)*Max(1,aCountArrayLayers)*Max(1,aCountFaces);

 Data:=nil;
 try

  SetLength(Data,DataSize);

  case aDefaultType of
   vtdtCheckerboard:begin
    for LayerIndex:=0 to (Max(1,aDepth)*Max(1,aCountArrayLayers)*Max(1,aCountFaces))-1 do begin
     for y:=0 to aHeight-1 do begin
      for x:=0 to aWidth-1 do begin
       Offset:=(LayerIndex*LayerSize)+(((y*aWidth)+x)*TexelSize);
       if (((x shr BlockShift) xor (y shr BlockShift)) and 1)<>0 then begin
        if (LayerIndex and 1)<>0 then begin
         Data[Offset+0]:=160;
        end else begin
         Data[Offset+0]:=96;
        end;
        Data[Offset+1]:=64;
        if (LayerIndex and 1)<>0 then begin
         Data[Offset+2]:=96;
        end else begin
         Data[Offset+2]:=255;
        end;
       end else begin
        if (LayerIndex and 1)<>0 then begin
         Data[Offset+0]:=160;
        end else begin
         Data[Offset+0]:=64;
        end;
        Data[Offset+1]:=32;
        if (LayerIndex and 1)<>0 then begin
         Data[Offset+2]:=64;
        end else begin
         Data[Offset+2]:=255;
        end;
       end;
       Data[Offset+3]:=255;
      end;
     end;
    end;
   end;
   vtdtPyramids:begin
    for LayerIndex:=0 to (Max(1,aDepth)*Max(1,aCountArrayLayers)*Max(1,aCountFaces))-1 do begin
     for y:=0 to aHeight-1 do begin
      for x:=0 to aWidth-1 do begin
       Offset:=(LayerIndex*LayerSize)+(((y*aWidth)+x)*TexelSize);
       lx:=x and BlockMask;
       ly:=y and BlockMask;
       rx:=BlockMask-lx;
       ry:=BlockMask-ly;
       cx:=0;
       cy:=0;
       if (lx<>ly) and (lx<>ry) then begin
        m:=BlockSize;
        if lx<m then begin
         m:=lx;
         cx:=-96;
         cy:=0;
        end;
        if ly<m then begin
         m:=ly;
         cx:=0;
         cy:=-96;
        end;
        if rx<m then begin
         m:=rx;
         cx:=96;
         cy:=0;
        end;
        if ry<m then begin
         m:=ry;
         cx:=0;
         cy:=96;
        end;
        if m>0 then begin
        end;
       end;
       Data[Offset+0]:=128+cx;
       Data[Offset+1]:=128+cy;
       Data[Offset+2]:=128+85;
       Data[Offset+3]:=255;
      end;
     end;
    end;
   end;
   else {vtdtCircles:}begin
    for LayerIndex:=0 to (Max(1,aDepth)*Max(1,aCountArrayLayers)*Max(1,aCountFaces))-1 do begin
     for y:=0 to aHeight-1 do begin
      for x:=0 to aWidth-1 do begin
       Offset:=(LayerIndex*LayerSize)+(((y*aWidth)+x)*TexelSize);
       Index:=((((y shr (BlockShift-1)) and 2) xor ((y shr BlockShift) and 2))) or
              (((((y shr BlockShift) and 1) xor ((y shr (BlockShift+1)) and 1))));
       dx:=((x and not BlockMask)+(BlockSize shr 1))-x;
       dy:=((y and not BlockMask)+(BlockSize shr 1))-y;
       ds:=abs(((dx*dx)+(dy*dy))-(Radius*Radius));
       Scale:=Min(ds,BlockSize);
       Data[Offset+0]:=Min(Max((Colors[Index,0]*Scale) shr BlockShift,0),255);
       Data[Offset+1]:=Min(Max((Colors[Index,1]*Scale) shr BlockShift,0),255);
       Data[Offset+2]:=Min(Max((Colors[Index,2]*Scale) shr BlockShift,0),255);
       Data[Offset+3]:=255;
      end;
     end;
    end;
   end;
  end;

  if aBorder then begin
   for LayerIndex:=0 to (Max(1,aDepth)*Max(1,aCountArrayLayers)*Max(1,aCountFaces))-1 do begin
    for y:=0 to aHeight-1 do begin
     Offset:=(LayerIndex*LayerSize)+(((y*aWidth)+0)*TexelSize);
     Data[Offset+0]:=0;
     Data[Offset+1]:=0;
     Data[Offset+2]:=0;
     Data[Offset+3]:=255;
     Offset:=(LayerIndex*LayerSize)+(((y*aWidth)+(aWidth-1))*TexelSize);
     Data[Offset+0]:=0;
     Data[Offset+1]:=0;
     Data[Offset+2]:=0;
     Data[Offset+3]:=255;
    end;
    for x:=0 to aWidth-1 do begin
     Offset:=(LayerIndex*LayerSize)+(((0*aWidth)+x)*TexelSize);
     Data[Offset+0]:=0;
     Data[Offset+1]:=0;
     Data[Offset+2]:=0;
     Data[Offset+3]:=255;
     Offset:=(LayerIndex*LayerSize)+((((aHeight-1)*aWidth)+x)*TexelSize);
     Data[Offset+0]:=0;
     Data[Offset+1]:=0;
     Data[Offset+2]:=0;
     Data[Offset+3]:=255;
    end;
   end;
  end;

  if aMipMaps then begin
   CountMipMaps:=-1;
  end else begin
   CountMipMaps:=1;
  end;

  CreateFromMemory(aDevice,
                   aGraphicsQueue,
                   aGraphicsCommandBuffer,
                   aGraphicsFence,
                   aTransferQueue,
                   aTransferCommandBuffer,
                   aTransferFence,
                   TVkFormat(TVkInt32(IfThen(aSRGB,TVkInt32(VK_FORMAT_R8G8B8A8_SRGB),TVkInt32(VK_FORMAT_R8G8B8A8_UNORM)))),
                   VK_SAMPLE_COUNT_1_BIT,
                   aWidth,
                   aHeight,
                   aDepth,
                   aCountArrayLayers,
                   aCountFaces,
                   CountMipMaps,
                   [vtufTransferDst,vtufSampled],
                   @Data[0],
                   DataSize,
                   false,
                   false,
                   1,
                   false);

 finally
  SetLength(Data,0);
 end;

end;

destructor TpvVulkanTexture.Destroy;
begin
 FreeAndNil(fSampler);
 FreeAndNil(fImageView);
 if assigned(fMemoryBlock) then begin
  fDevice.fMemoryManager.FreeMemoryBlock(fMemoryBlock);
  fMemoryBlock:=nil;
 end;
 FreeAndNil(fImage);
 inherited Destroy;
end;

procedure TpvVulkanTexture.Upload(const aGraphicsQueue:TpvVulkanQueue;
                                  const aGraphicsCommandBuffer:TpvVulkanCommandBuffer;
                                  const aGraphicsFence:TpvVulkanFence;
                                  const aTransferQueue:TpvVulkanQueue;
                                  const aTransferCommandBuffer:TpvVulkanCommandBuffer;
                                  const aTransferFence:TpvVulkanFence;
                                  const aData:TpvPointer;
                                  const aDataSize:TVkSizeInt;
                                  const aMipMapSizeStored:boolean=false;
                                  const aSwapEndianness:boolean=false;
                                  const aSwapEndiannessTexels:TpvInt32=0;
                                  const aDDSStructure:boolean=true;
                                  const aStagingBuffer:TpvVulkanBuffer=nil);
type PpvUInt8Array=^TpvUInt8Array;
     TpvUInt8Array=array[0..65535] of TpvUInt8;
 function Swap16(x:TpvUInt16):TpvUInt16;
 begin
  result:=((x and $ff) shl 8) or ((x and $ff00) shr 8);
 end;
 function Swap32(x:TpvUInt32):TpvUInt32;
 begin
  result:=(Swap16(x and $ffff) shl 16) or Swap16((x and $ffff0000) shr 16);
 end;
 function Swap64(x:TpvInt64):TpvUInt64;
 begin
  result:=(TpvUInt64(Swap32(x and TpvUInt64($ffffffff))) shl 32) or Swap32((x and TpvUInt64($ffffffff00000000)) shr 32);
 end;
 procedure GetMipMapSize(const aFormat:TVkFormat;const aMipMapWidth,aMipMapHeight:TpvInt32;out aMipMapSize:TVkUInt32;out aCompressed:boolean);
 begin
  case aFormat of
   VK_FORMAT_R8_UNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8_UNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8B8A8_UNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8_SNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8_SNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8B8_SNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8B8_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8B8_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8_SRGB:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8_SRGB:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R8G8B8A8_SRGB:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt8);
    aCompressed:=false;
   end;
   VK_FORMAT_R16_UNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16_UNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16B16A16_UNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16_SNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16_SNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16B16A16_SNORM:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16B16A16_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16B16A16_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16_SFLOAT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16_SFLOAT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R16G16B16A16_SFLOAT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt16);
    aCompressed:=false;
   end;
   VK_FORMAT_R32_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvUInt32);
    aCompressed:=false;
   end;
   VK_FORMAT_R32G32_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvUInt32);
    aCompressed:=false;
   end;
   VK_FORMAT_R32G32B32A32_UINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvUInt32);
    aCompressed:=false;
   end;
   VK_FORMAT_R32_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(TpvInt32);
    aCompressed:=false;
   end;
   VK_FORMAT_R32G32_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(TpvInt32);
    aCompressed:=false;
   end;
   VK_FORMAT_R32G32B32A32_SINT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(TpvInt32);
    aCompressed:=false;
   end;
   VK_FORMAT_R32_SFLOAT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*1*SizeOf(single);
    aCompressed:=false;
   end;
   VK_FORMAT_R32G32_SFLOAT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*2*SizeOf(single);
    aCompressed:=false;
   end;
   VK_FORMAT_R32G32B32A32_SFLOAT:begin
    aMipMapSize:=aMipMapHeight*aMipMapWidth*4*SizeOf(single);
    aCompressed:=false;
   end;
   VK_FORMAT_BC1_RGB_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_BC1_RGBA_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_BC2_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_BC3_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_BC1_RGB_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_BC1_RGBA_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_BC2_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_BC3_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_BC4_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_BC5_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_BC4_SNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_BC5_SNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ETC2_R8G8B8_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_ETC2_R8G8B8A1_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_ETC2_R8G8B8A8_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ETC2_R8G8B8_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_ETC2_R8G8B8A1_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_ETC2_R8G8B8A8_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_EAC_R11_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_EAC_R11G11_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_EAC_R11_SNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*8;
    aCompressed:=true;
   end;
   VK_FORMAT_EAC_R11G11_SNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_4x4_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_5x4_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+4) div 5)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_5x5_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+4) div 5)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_6x5_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+5) div 6)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_6x6_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+5) div 6)*((aMipMapWidth+5) div 6)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_8x5_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+7) div 8)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_8x6_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+5) div 6)*((aMipMapWidth+7) div 8)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_8x8_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+7) div 8)*((aMipMapWidth+7) div 8)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x5_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x6_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+5) div 6)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x8_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+7) div 8)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x10_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+9) div 10)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_12x10_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+9) div 10)*((aMipMapWidth+11) div 12)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_12x12_UNORM_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+11) div 12)*((aMipMapWidth+11) div 12)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_4x4_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+3) div 4)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_5x4_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+3) div 4)*((aMipMapWidth+4) div 5)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_5x5_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+4) div 5)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_6x5_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+5) div 6)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_6x6_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+5) div 6)*((aMipMapWidth+5) div 6)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_8x5_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+7) div 8)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_8x6_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+5) div 6)*((aMipMapWidth+7) div 8)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_8x8_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+7) div 8)*((aMipMapWidth+7) div 8)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x5_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+4) div 5)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x6_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+5) div 6)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x8_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+7) div 8)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_10x10_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+9) div 10)*((aMipMapWidth+9) div 10)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_12x10_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+9) div 10)*((aMipMapWidth+11) div 12)*16;
    aCompressed:=true;
   end;
   VK_FORMAT_ASTC_12x12_SRGB_BLOCK:begin
    aMipMapSize:=((aMipMapHeight+11) div 12)*((aMipMapWidth+11) div 12)*16;
    aCompressed:=true;
   end;
   else begin
    raise EpvVulkanTextureException.Create('Non-supported texture image format ('+IntToStr(TpvInt32(aFormat))+')');
   end;
  end;
 end;
var BufferImageCopyArraySize,MipMapLevelIndex,MipMapWidth,MipMapHeight,MipMapDepth,
    LayerIndex,DepthIndex,PreviousMipMapLevelIndex:TpvInt32;
    DataOffset,TotalMipMapSize,StoredMipMapSize,MipMapSize,Index:TpvUInt32;
    v16:PpvUInt16;
    v32:PpvUInt32;
    v64:PpvUInt64;
    Compressed:boolean;
    StagingBuffer:TpvVulkanBuffer;
    BufferMemoryBarrier:TVkBufferMemoryBarrier;
    BufferImageCopyArray:TVkBufferImageCopyArray;
    BufferImageCopy:PVkBufferImageCopy;
    ImageMemoryBarrier:TVkImageMemoryBarrier;
    ImageBlit:TVkImageBlit;
begin

 if assigned(aData) then begin

  if fSampleCount<>VK_SAMPLE_COUNT_1_BIT then begin
   raise EpvVulkanTextureException.Create('Sample count must be 1 bit');
  end;

  if assigned(aStagingBuffer) then begin
   StagingBuffer:=aStagingBuffer;
  end else begin
   StagingBuffer:=TpvVulkanBuffer.Create(fDevice,
                                         aDataSize,
                                         TVkBufferUsageFlags(VK_BUFFER_USAGE_TRANSFER_SRC_BIT),
                                         TVkSharingMode(TpvInt32(IfThen(aGraphicsQueue=aTransferQueue,TpvInt32(VK_SHARING_MODE_EXCLUSIVE),TpvInt32(VK_SHARING_MODE_CONCURRENT)))),
                                         nil,
                                         TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT),
                                         TVkMemoryPropertyFlags(VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT),
                                         0,
                                         0,
                                         0,
                                         0,
                                         [vbfOwnSingleMemoryChunk]);
  end;
  try

   Compressed:=false;

   if (not aDDSStructure) and (aSwapEndianness and (aSwapEndiannessTexels in [2,4,8])) then begin
    DataOffset:=0;
    for MipMapLevelIndex:=0 to fCountDataLevels-1 do begin
     MipMapWidth:=Max(1,Max(1,fWidth) shr MipMapLevelIndex);
     MipMapHeight:=Max(1,Max(1,fHeight) shr MipMapLevelIndex);
     MipMapDepth:=Max(1,Max(1,fDepth) shr MipMapLevelIndex);
     TotalMipMapSize:=0;
     StoredMipMapSize:=0;
     if aMipMapSizeStored then begin
      Assert(TVkSizeInt(DataOffset+SizeOf(TpvUInt32))<=TVkSizeInt(aDataSize));
      StoredMipMapSize:=TpvUInt32(TpvPointer(@TpvUInt8Array(TpvPointer(aData)^)[DataOffset])^);
      inc(DataOffset,SizeOf(TpvUInt32));
      if aSwapEndianness then begin
       StoredMipMapSize:=Swap32(StoredMipMapSize);
      end;
      if StoredMipMapSize<>0 then begin
      end;
     end;
     for LayerIndex:=0 to Max(1,fTotalCountArrayLayers)-1 do begin
      for DepthIndex:=0 to MipMapDepth-1 do begin
       MipMapSize:=0;
       GetMipMapSize(fFormat,MipMapWidth,MipMapHeight,MipMapSize,Compressed);
       Assert(TVkSizeInt(DataOffset+MipMapSize)<=TVkSizeInt(aDataSize));
       case aSwapEndiannessTexels of
        2:begin
         v16:=TpvPointer(TpvPtrUInt(TpvPtrUInt(TpvPointer(aData))+TpvPtrUInt(DataOffset)));
         for Index:=1 to MipMapSize shr 1 do begin
          v16^:=Swap16(v16^);
          inc(v16);
         end;
        end;
        4:begin
         v32:=TpvPointer(TpvPtrUInt(TpvPtrUInt(TpvPointer(aData))+TpvPtrUInt(DataOffset)));
         for Index:=1 to MipMapSize shr 2 do begin
          v32^:=Swap32(v32^);
          inc(v32);
         end;
        end;
        8:begin
         v64:=TpvPointer(TpvPtrUInt(TpvPtrUInt(TpvPointer(aData))+TpvPtrUInt(DataOffset)));
         for Index:=1 to MipMapSize shr 3 do begin
          v64^:=Swap64(v64^);
          inc(v64);
         end;
        end;
       end;
       inc(TotalMipMapSize,MipMapSize);
       inc(DataOffset,MipMapSize);
       if aMipMapSizeStored and ((fDepth<=1) and (fTotalCountArrayLayers<=1)) then begin
        Assert(TotalMipMapSize=StoredMipMapSize);
        inc(DataOffset,3-((MipMapSize+3) and 3));
       end;
      end;
     end;
     if aMipMapSizeStored and ((fDepth>1) or (fTotalCountArrayLayers>1)) then begin
      Assert(TotalMipMapSize=StoredMipMapSize);
      inc(DataOffset,3-((TotalMipMapSize+3) and 3));
     end;
    end;
   end;

   StagingBuffer.UploadData(aTransferQueue,
                            aTransferCommandBuffer,
                            aTransferFence,
                            aData^,
                            0,
                            aDataSize,
                            vbutsbmNo);

   BufferImageCopyArray:=nil;
   try

    aGraphicsCommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
    aGraphicsCommandBuffer.BeginRecording;
    try

     FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
     ImageMemoryBarrier.srcAccessMask:=0;
     ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
     ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
     ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_UNDEFINED;
     ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
     ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     ImageMemoryBarrier.image:=fImage.fImageHandle;
     ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
     ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
     ImageMemoryBarrier.subresourceRange.levelCount:=fCountStorageLevels;
     ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
     ImageMemoryBarrier.subresourceRange.layerCount:=Max(1,fTotalCountArrayLayers);
     aGraphicsCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                               TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                               0,
                                               0,
                                               nil,
                                               0,
                                               nil,
                                               1,
                                               @ImageMemoryBarrier);

     FillChar(BufferMemoryBarrier,SizeOf(TVkBufferMemoryBarrier),#0);
     BufferMemoryBarrier.sType:=VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER;
     BufferMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_HOST_WRITE_BIT);
     BufferMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
     if aGraphicsQueue<>aTransferQueue then begin
      BufferMemoryBarrier.srcQueueFamilyIndex:=aTransferQueue.fQueueFamilyIndex;
      BufferMemoryBarrier.dstQueueFamilyIndex:=aGraphicsQueue.fQueueFamilyIndex;
     end else begin
      BufferMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
      BufferMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     end;
     BufferMemoryBarrier.buffer:=StagingBuffer.fBufferHandle;
     BufferMemoryBarrier.offset:=StagingBuffer.Memory.fOffset;
     BufferMemoryBarrier.size:=aDataSize;
     aGraphicsCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                               TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                               0,
                                               0,
                                               nil,
                                               1,
                                               @BufferMemoryBarrier,
                                               0,
                                               nil);

     SetLength(BufferImageCopyArray,fCountDataLevels*Max(1,fTotalCountArrayLayers)*Max(1,fDepth));
     BufferImageCopyArraySize:=0;
     DataOffset:=0;
     if aDDSStructure then begin
      for LayerIndex:=0 to Max(1,fTotalCountArrayLayers)-1 do begin
       for MipMapLevelIndex:=0 to fCountDataLevels-1 do begin
        MipMapWidth:=Max(1,Max(1,fWidth) shr MipMapLevelIndex);
        MipMapHeight:=Max(1,Max(1,fHeight) shr MipMapLevelIndex);
        MipMapDepth:=Max(1,Max(1,fDepth) shr MipMapLevelIndex);
        for DepthIndex:=0 to MipMapDepth-1 do begin
         BufferImageCopy:=@BufferImageCopyArray[BufferImageCopyArraySize];
         inc(BufferImageCopyArraySize);
         FillChar(BufferImageCopy^,SizeOf(TVkBufferImageCopy),#0);
         BufferImageCopy^.bufferOffset:=DataOffset;
         BufferImageCopy^.bufferRowLength:=0;
         BufferImageCopy^.bufferImageHeight:=0;
         BufferImageCopy^.imageSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
         BufferImageCopy^.imageSubresource.mipLevel:=MipMapLevelIndex;
         BufferImageCopy^.imageSubresource.baseArrayLayer:=LayerIndex;
         BufferImageCopy^.imageSubresource.layerCount:=1;
         BufferImageCopy^.imageOffset.x:=0;
         BufferImageCopy^.imageOffset.y:=0;
         BufferImageCopy^.imageOffset.z:=DepthIndex;
         BufferImageCopy^.imageExtent.width:=Max(1,fWidth);
         BufferImageCopy^.imageExtent.height:=Max(1,fHeight);
         BufferImageCopy^.imageExtent.depth:=1;
         MipMapSize:=0;
         GetMipMapSize(fFormat,MipMapWidth,MipMapHeight,MipMapSize,Compressed);
         Assert(TVkSizeInt(DataOffset+MipMapSize)<=TVkSizeInt(aDataSize));
         inc(DataOffset,MipMapSize);
        end;
       end;
      end;
     end else begin
      for MipMapLevelIndex:=0 to fCountDataLevels-1 do begin
       MipMapWidth:=Max(1,Max(1,fWidth) shr MipMapLevelIndex);
       MipMapHeight:=Max(1,Max(1,fHeight) shr MipMapLevelIndex);
       MipMapDepth:=Max(1,Max(1,fDepth) shr MipMapLevelIndex);
       TotalMipMapSize:=0;
       StoredMipMapSize:=0;
       if aMipMapSizeStored then begin
        Assert(TVkSizeInt(DataOffset+SizeOf(TpvUInt32))<=TVkSizeInt(aDataSize));
        StoredMipMapSize:=TpvUInt32(TpvPointer(@TpvUInt8Array(TpvPointer(aData)^)[DataOffset])^);
        inc(DataOffset,SizeOf(TpvUInt32));
        if aSwapEndianness then begin
         StoredMipMapSize:=Swap32(StoredMipMapSize);
        end;
        if StoredMipMapSize<>0 then begin
        end;
       end;
       for LayerIndex:=0 to Max(1,fTotalCountArrayLayers)-1 do begin
        for DepthIndex:=0 to MipMapDepth-1 do begin
         BufferImageCopy:=@BufferImageCopyArray[BufferImageCopyArraySize];
         inc(BufferImageCopyArraySize);
         FillChar(BufferImageCopy^,SizeOf(TVkBufferImageCopy),#0);
         BufferImageCopy^.bufferOffset:=DataOffset;
         BufferImageCopy^.bufferRowLength:=0;
         BufferImageCopy^.bufferImageHeight:=0;
         BufferImageCopy^.imageSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
         BufferImageCopy^.imageSubresource.mipLevel:=MipMapLevelIndex;
         BufferImageCopy^.imageSubresource.baseArrayLayer:=LayerIndex;
         BufferImageCopy^.imageSubresource.layerCount:=1;
         BufferImageCopy^.imageOffset.x:=0;
         BufferImageCopy^.imageOffset.y:=0;
         BufferImageCopy^.imageOffset.z:=DepthIndex;
         BufferImageCopy^.imageExtent.width:=Max(1,fWidth);
         BufferImageCopy^.imageExtent.height:=Max(1,fHeight);
         BufferImageCopy^.imageExtent.depth:=1;
         MipMapSize:=0;
         GetMipMapSize(fFormat,MipMapWidth,MipMapHeight,MipMapSize,Compressed);
         Assert(TVkSizeInt(DataOffset+MipMapSize)<=TVkSizeInt(aDataSize));
         inc(TotalMipMapSize,MipMapSize);
         inc(DataOffset,MipMapSize);
         if aMipMapSizeStored and ((fDepth<=1) and (fTotalCountArrayLayers<=1)) then begin
          Assert(TotalMipMapSize=StoredMipMapSize);
          inc(DataOffset,3-((MipMapSize+3) and 3));
         end;
        end;
       end;
       if aMipMapSizeStored and ((fDepth>1) or (fTotalCountArrayLayers>1)) then begin
        Assert(TotalMipMapSize=StoredMipMapSize);
        inc(DataOffset,3-((TotalMipMapSize+3) and 3));
       end;
      end;
     end;
     SetLength(BufferImageCopyArray,BufferImageCopyArraySize);

     Assert(TVkSizeInt(DataOffset)=TVkSizeInt(aDataSize));

     aGraphicsCommandBuffer.CmdCopyBufferToImage(StagingBuffer.fBufferHandle,fImage.fImageHandle,VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,BufferImageCopyArraySize,@BufferImageCopyArray[0]);

     if fCountMipMaps<1 then begin

      if Compressed then begin
       raise EpvVulkanTextureException.Create('Mip map levels can''t generated for compressed textures automatically');
      end;

      for MipMapLevelIndex:=1 to fCountStorageLevels do begin

       PreviousMipMapLevelIndex:=MipMapLevelIndex-1;

       FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
       ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
       ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
       ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
       ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
       ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
       ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
       ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
       ImageMemoryBarrier.image:=fImage.fImageHandle;
       ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
       ImageMemoryBarrier.subresourceRange.baseMipLevel:=PreviousMipMapLevelIndex;
       ImageMemoryBarrier.subresourceRange.levelCount:=1;
       ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
       ImageMemoryBarrier.subresourceRange.layerCount:=Max(1,fTotalCountArrayLayers);
       aGraphicsCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                                 TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                                 0,
                                                 0,
                                                 nil,
                                                 0,
                                                 nil,
                                                 1,
                                                 @ImageMemoryBarrier);

       if MipMapLevelIndex<fCountStorageLevels then begin
        FillChar(ImageBlit,SizeOf(TVkImageBlit),#0);
        ImageBlit.srcSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
        ImageBlit.srcSubresource.mipLevel:=PreviousMipMapLevelIndex;
        ImageBlit.srcSubresource.baseArrayLayer:=0;
        ImageBlit.srcSubresource.layerCount:=Max(1,fTotalCountArrayLayers);
        ImageBlit.srcOffsets[0].x:=0;
        ImageBlit.srcOffsets[0].y:=0;
        ImageBlit.srcOffsets[0].z:=0;
        ImageBlit.srcOffsets[1].x:=Max(1,Max(1,fWidth) shr PreviousMipMapLevelIndex);
        ImageBlit.srcOffsets[1].y:=Max(1,Max(1,fHeight) shr PreviousMipMapLevelIndex);
        ImageBlit.srcOffsets[1].z:=Max(1,Max(1,fDepth) shr PreviousMipMapLevelIndex);
        ImageBlit.dstSubresource.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
        ImageBlit.dstSubresource.mipLevel:=MipMapLevelIndex;
        ImageBlit.dstSubresource.baseArrayLayer:=0;
        ImageBlit.dstSubresource.layerCount:=Max(1,fTotalCountArrayLayers);
        ImageBlit.dstOffsets[0].x:=0;
        ImageBlit.dstOffsets[0].y:=0;
        ImageBlit.dstOffsets[0].z:=0;
        ImageBlit.dstOffsets[1].x:=Max(1,Max(1,fWidth) shr MipMapLevelIndex);
        ImageBlit.dstOffsets[1].y:=Max(1,Max(1,fHeight) shr MipMapLevelIndex);
        ImageBlit.dstOffsets[1].z:=Max(1,Max(1,fDepth) shr MipMapLevelIndex);
        aGraphicsCommandBuffer.CmdBlitImage(fImage.fImageHandle,
                                            VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL,
                                            fImage.fImageHandle,
                                            VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                            1,
                                            @ImageBlit,
                                            VK_FILTER_LINEAR);
       end;

      end;

     end;

     FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
     ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
     if fCountMipMaps>=1 then begin
      ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_WRITE_BIT);
     end else begin
      ImageMemoryBarrier.srcAccessMask:=TVkAccessFlags(VK_ACCESS_TRANSFER_READ_BIT);
     end;
     ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT) or TVkAccessFlags(VK_ACCESS_INPUT_ATTACHMENT_READ_BIT);
     if fCountMipMaps>=1 then begin
      ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
     end else begin
      ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
     end;
     ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
     ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
     ImageMemoryBarrier.image:=fImage.fImageHandle;
     ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
     ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
     ImageMemoryBarrier.subresourceRange.levelCount:=fCountStorageLevels;
     ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
     ImageMemoryBarrier.subresourceRange.layerCount:=Max(1,fTotalCountArrayLayers);
     aGraphicsCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                               TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                               0,
                                               0,
                                               nil,
                                               0,
                                               nil,
                                               1,
                                               @ImageMemoryBarrier);

    finally
     aGraphicsCommandBuffer.EndRecording;
     aGraphicsCommandBuffer.Execute(aGraphicsQueue,0,nil,nil,aGraphicsFence,true);
    end;

   finally
    SetLength(BufferImageCopyArray,0);
   end;

  finally
   if (StagingBuffer<>aStagingBuffer) or not assigned(aStagingBuffer) then begin
    StagingBuffer.Free;
   end;
  end;

 end else begin

  FillChar(ImageMemoryBarrier,SizeOf(TVkImageMemoryBarrier),#0);
  ImageMemoryBarrier.sType:=VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER;
  ImageMemoryBarrier.srcAccessMask:=0;
  ImageMemoryBarrier.dstAccessMask:=TVkAccessFlags(VK_ACCESS_SHADER_READ_BIT);
  ImageMemoryBarrier.oldLayout:=VK_IMAGE_LAYOUT_UNDEFINED;
  ImageMemoryBarrier.newLayout:=VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
  ImageMemoryBarrier.srcQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
  ImageMemoryBarrier.dstQueueFamilyIndex:=VK_QUEUE_FAMILY_IGNORED;
  ImageMemoryBarrier.image:=fImage.fImageHandle;
  ImageMemoryBarrier.subresourceRange.aspectMask:=TVkImageAspectFlags(VK_IMAGE_ASPECT_COLOR_BIT);
  ImageMemoryBarrier.subresourceRange.baseMipLevel:=0;
  ImageMemoryBarrier.subresourceRange.levelCount:=fCountStorageLevels;
  ImageMemoryBarrier.subresourceRange.baseArrayLayer:=0;
  ImageMemoryBarrier.subresourceRange.layerCount:=Max(1,fTotalCountArrayLayers);
  aGraphicsCommandBuffer.Reset(TVkCommandBufferResetFlags(VK_COMMAND_BUFFER_RESET_RELEASE_RESOURCES_BIT));
  aGraphicsCommandBuffer.BeginRecording;
  aGraphicsCommandBuffer.CmdPipelineBarrier(TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                            TVkPipelineStageFlags(VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT),
                                            0,
                                            0,
                                            nil,
                                            0,
                                            nil,
                                            1,
                                            @ImageMemoryBarrier);
  aGraphicsCommandBuffer.EndRecording;
  aGraphicsCommandBuffer.Execute(aGraphicsQueue,0,nil,nil,aGraphicsFence,true);

 end;

end;

procedure TpvVulkanTexture.UpdateSampler;
var MagFilter:TVkFilter;
    MinFilter:TVkFilter;
    MipmapMode:TVkSamplerMipmapMode;
    AddressModeU:TVkSamplerAddressMode;
    AddressModeV:TVkSamplerAddressMode;
    AddressModeW:TVkSamplerAddressMode;
    AnisotropyEnable:boolean;
begin
 FreeAndNil(fSampler);
 case fFilterMode of
  vtfmNearest:begin
   MagFilter:=VK_FILTER_NEAREST;
   MinFilter:=VK_FILTER_NEAREST;
   MipmapMode:=VK_SAMPLER_MIPMAP_MODE_NEAREST;
  end;
  vtfmLinear:begin
   MagFilter:=VK_FILTER_LINEAR;
   MinFilter:=VK_FILTER_LINEAR;
   MipmapMode:=VK_SAMPLER_MIPMAP_MODE_NEAREST;
  end;
  else {vtfmBilinear:}begin
   MagFilter:=VK_FILTER_LINEAR;
   MinFilter:=VK_FILTER_LINEAR;
   MipmapMode:=VK_SAMPLER_MIPMAP_MODE_LINEAR;
  end;
 end;
 case fWrapModeU of
  vtwmRepeat:begin
   AddressModeU:=VK_SAMPLER_ADDRESS_MODE_REPEAT;
  end;
  vtwmMirroredRepeat:begin
   AddressModeU:=VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
  end;
  vtwmClampToEdge:begin
   AddressModeU:=VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
  end;
  vtwmClampToBorder:begin
   AddressModeU:=VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
  end;
  else {vtwmMirrorClampToEdge:}begin
   AddressModeU:=VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE;
  end;
 end;
 case fWrapModeV of
  vtwmRepeat:begin
   AddressModeV:=VK_SAMPLER_ADDRESS_MODE_REPEAT;
  end;
  vtwmMirroredRepeat:begin
   AddressModeV:=VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
  end;
  vtwmClampToEdge:begin
   AddressModeV:=VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
  end;
  vtwmClampToBorder:begin
   AddressModeV:=VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
  end;
  else {vtwmMirrorClampToEdge:}begin
   AddressModeV:=VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE;
  end;
 end;
 case fWrapModeW of
  vtwmRepeat:begin
   AddressModeW:=VK_SAMPLER_ADDRESS_MODE_REPEAT;
  end;
  vtwmMirroredRepeat:begin
   AddressModeW:=VK_SAMPLER_ADDRESS_MODE_MIRRORED_REPEAT;
  end;
  vtwmClampToEdge:begin
   AddressModeW:=VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_EDGE;
  end;
  vtwmClampToBorder:begin
   AddressModeW:=VK_SAMPLER_ADDRESS_MODE_CLAMP_TO_BORDER;
  end;
  else {vtwmMirrorClampToEdge:}begin
   AddressModeW:=VK_SAMPLER_ADDRESS_MODE_MIRROR_CLAMP_TO_EDGE;
  end;
 end;
 AnisotropyEnable:=fMaxAnisotropy>1.0;
 fSampler:=TpvVulkanSampler.Create(fDevice,
                                 MagFilter,
                                 MinFilter,
                                 MipmapMode,
                                 AddressModeU,
                                 AddressModeV,
                                 AddressModeW,
                                 0.0,
                                 AnisotropyEnable,
                                 fMaxAnisotropy,
                                 false,
                                 VK_COMPARE_OP_NEVER,
                                 0.0,
                                 fCountStorageLevels,
                                 fBorderColor,
                                 false);
 if assigned(fSampler) then begin
  fDescriptorImageInfo.sampler:=fSampler.fSamplerHandle;
 end else begin
  fDescriptorImageInfo.sampler:=VK_NULL_HANDLE;
 end;
end;

initialization
finalization
end.


