// Copyright (c) EZBLOCK Inc & AUTHORS
// SPDX-License-Identifier: BSD-3-Clause

import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertChip extends Chip {
  AlertChip(Alert alert, {Key? key, Function()? onDeleted})
      : super(
          key: key,
          label: Text(alert.text),
          labelStyle: TextStyle(color: alert.color),
          onDeleted: onDeleted,
        );
}
