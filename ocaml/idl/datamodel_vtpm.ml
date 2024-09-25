(*
   Copyright (C) Citrix Systems Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as published
   by the Free Software Foundation; version 2.1 only. with the special
   exception on linking described in file LICENSE.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.
 *)

open Datamodel_types
open Datamodel_common
open Datamodel_roles

let persistence_backend =
  Enum ("persistence_backend", [("xapi", "This VTPM is persisted in XAPI's DB")])

let create =
  call ~name:"create" ~lifecycle:[]
    ~doc:"Create a new VTPM instance, and return its handle."
    ~params:
      [
        (Ref _vm, "vM", "The VM reference the VTPM will be attached to")
      ; (Bool, "is_unique", "Whether the VTPM must be unique")
      ]
    ~result:(Ref _vtpm, "The reference of the newly created VTPM")
    ~allowed_roles:_R_VM_ADMIN ()

let destroy =
  call ~name:"destroy" ~lifecycle:[]
    ~doc:"Destroy the specified VTPM instance, along with its state."
    ~params:[(Ref _vtpm, "self", "The reference to the VTPM object")]
    ~allowed_roles:_R_VM_ADMIN ()

let get_contents =
  call ~name:"get_contents" ~lifecycle:[] ~doc:"Obtain the contents of the TPM"
    ~secret:true
    ~params:[(Ref _vtpm, "self", "The VTPM reference")]
    ~result:(String, "The contents") ~hide_from_docs:true
    ~allowed_roles:_R_LOCAL_ROOT_ONLY ()

let set_contents =
  call ~name:"set_contents" ~lifecycle:[]
    ~doc:"Introduce new contents for the TPM" ~secret:true
    ~params:
      [
        (Ref _vtpm, "self", "The VTPM reference")
      ; (String, "contents", "The new contents")
      ]
    ~hide_from_docs:true ~allowed_roles:_R_LOCAL_ROOT_ONLY ()

let operations =
  Enum
    ( "vtpm_operations"
    , [
        ("destroy", "Destroy a VTPM")
        (* these are undocumented, so don't have ops for them
           ; ("get_contents", "Read data from a VTPM")
           ; ("set_contents", "Write to the VTPM, overwriting existing content")
        *)
      ]
    )

let t =
  create_obj ~in_db:true ~in_oss_since:oss_since_303 ~persist:PersistEverything
    ~lifecycle:[] ~gen_constructor_destructor:false ~name:_vtpm
    ~descr:"A virtual TPM device" ~gen_events:true ~doccomments:[]
    ~messages_default_allowed_roles:_R_POOL_ADMIN
    ~contents:
      (List.concat
         [
           [
             uid _vtpm
               ~lifecycle:
                 [(Published, rel_rio, "Unique identifier/object reference")]
           ]
         ; allowed_and_current_operations operations
         ; [
             field ~qualifier:StaticRO ~ty:(Ref _vm) "VM"
               ~lifecycle:
                 [
                   ( Published
                   , rel_rio
                   , "The virtual machine the TPM is attached to"
                   )
                 ]
               "The virtual machine the TPM is attached to"
           ; field ~qualifier:DynamicRO ~ty:(Ref _vm) "backend"
               ~lifecycle:
                 [
                   ( Published
                   , rel_rio
                   , "The domain where the backend is located (unused)"
                   )
                 ]
               ~default_value:(Some (VRef null_ref))
               "The domain where the backend is located (unused)"
           ; field ~qualifier:DynamicRO ~ty:persistence_backend
               ~default_value:(Some (VEnum "xapi")) ~lifecycle:[]
               "persistence_backend" "The backend where the vTPM is persisted"
           ; field ~qualifier:StaticRO ~ty:Bool
               ~default_value:(Some (VBool false)) ~lifecycle:[] "is_unique"
               "Whether the contents are never copied, satisfying the TPM spec"
           ; field ~qualifier:DynamicRO ~ty:Bool
               ~default_value:(Some (VBool false)) ~lifecycle:[] "is_protected"
               "Whether the contents of the VTPM are secured according to the \
                TPM spec"
           ; field ~qualifier:DynamicRO ~ty:(Ref _secret) ~internal_only:true
               ~lifecycle:[] "contents" "The contents of the TPM"
           ]
         ]
      )
    ~messages:[create; destroy; get_contents; set_contents]
    ()
