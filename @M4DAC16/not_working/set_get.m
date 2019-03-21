
    %---------------------------------------------------------------------------
    % trigger level seems to reset itself every line
    function set.triggerLevel(DAQ, tl)
      % Get boundaries and step size of trigger levels
      [err(1), ext0.min]  = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT_AVAIL0_MIN'));
      [err(2), ext0.max]  = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT_AVAIL0_MAX'));
      [err(3), ext0.step] = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT_AVAIL0_STEP'));
      [err(4), ext1.min]  = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT_AVAIL1_MIN'));
      [err(5), ext1.max]  = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT_AVAIL1_MAX'));
      [err(6), ext1.step] = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT_AVAIL1_STEP'));
      if max(err)
        error('Could not read available trigger levels from card');
      end

      % check if trigger levels are in range
      if (tl.ext0_0 < ext0.min)
        warning('trigger ext0_0 too low, rising to minimum');
        tl.ext0_0 = ext0.min;
      elseif (tl.ext0_0 > ext0.max)
        warning('trigger ext0_0 too high, rising to maximum');
        tl.ext0_0 = ext0.max;
      else
        nSteps = round((tl.ext0_0 - ext0.min)/ext0.step);
        t1.ext0_0 = ext0.min + nSteps * ext0.step;
      end

      % check if trigger levels are in range
      if (tl.ext0_1 < ext0.min)
        warning('trigger ext0_1 too low, rising to minimum');
        tl.ext0_1 = ext0.min;
      elseif (tl.ext0_1 > ext0.max)
        warning('trigger ext0_0 too high, rising to maximum');
        tl.ext0_1 = ext0.max;
      else
        nSteps = round((tl.ext0_1 - ext0.min)/ext0.step);
        t1.ext0_1 = ext0.min + nSteps * ext0.step;
      end

      % check if trigger levels are in range
      if (tl.ext1_0 < ext1.min)
        warning('trigger ext0_0 too low, rising to minimum');
        tl.ext1_0 = ext1.min;
      elseif (tl.ext1_0 > ext1.max)
        warning('trigger ext0_0 too high, rising to maximum');
        tl.ext1_0 = ext1.max;
      else
        nSteps = round((tl.ext1_0 - ext1.min)/ext0.step);
        t1.ext1_0 = ext1.min + nSteps * ext1.step;
      end

      % push all informations to card
      err2 = spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, mRegs('SPC_TRIG_EXT0_LEVEL0'), int32(t1.ext0_0));
      err2 = err2 + spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, mRegs('SPC_TRIG_EXT0_LEVEL1'), int32(t1.ext0_1));
      err2 = err2 + spcm_dwSetParam_i32(DAQ.cardInfo.hDrv, mRegs('SPC_TRIG_EXT1_LEVEL0'), int32(t1.ext1_0));

      if err2
        error('Could not set trigger levels');
      end

    end

    function tl = get.triggerLevel(DAQ)
      [err, tl.ext0_0] = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT0_LEVEL0'));
      if err
        short_warn('Could not read trigger level 0 of ext0');
      end
      [err, tl.ext0_1] = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT0_LEVEL1'));
      if err
        short_warn('Could not read trigger level 1 of ext0');
      end
      [err, tl.ext1_0] = spcm_dwGetParam_i32(DAQ.cardInfo.hDrv, DAQ.mRegs('SPC_TRIG_EXT1_LEVEL1'));
      if err
        short_warn('Could not read trigger level 0 of ext1');
      end
    end
