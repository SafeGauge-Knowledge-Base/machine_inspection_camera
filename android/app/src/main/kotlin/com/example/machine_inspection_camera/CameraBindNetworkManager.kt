package com.arashivision.sdk.demo.util

import android.app.ActivityManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkInfo
import android.os.Build
import android.os.Process
import android.text.TextUtils

class CameraBindNetworkManager private constructor(private val context: Context) {

    enum class ErrorCode {
        OK, BIND_NETWORK_FAIL
    }

    private var mHasBindNetwork = false
    private var mIsBindingNetwork = false
    private var mProcessName: String? = null

    companion object {
        private const val ACTION_BIND_NETWORK_NOTIFY = "com.arashivision.sdk.demo.ACTION_BIND_NETWORK_NOTIFY"
        private const val EXTRA_KEY_IS_BIND = "extra_key_is_bind"

        @Volatile
        private var sInstance: CameraBindNetworkManager? = null

        fun getInstance(context: Context): CameraBindNetworkManager {
            return sInstance ?: synchronized(this) {
                sInstance ?: CameraBindNetworkManager(context).also { sInstance = it }
            }
        }
    }

    fun initWithOtherProcess() {
        mProcessName = processName
        bindNetwork(null)
        registerChildProcessBindNetworkReceiver()
    }

    private fun registerChildProcessBindNetworkReceiver() {
        val intentFilter = IntentFilter().apply {
            addAction(ACTION_BIND_NETWORK_NOTIFY)
        }
        context.registerReceiver(mOtherProcessBindNetworkReceiver, intentFilter)
    }

    fun notifyOtherProcessBind(isBind: Boolean) {
        val intent = Intent().apply {
            action = ACTION_BIND_NETWORK_NOTIFY
            putExtra(EXTRA_KEY_IS_BIND, isBind)
        }
        context.sendBroadcast(intent)
    }

    fun bindNetwork(bindNetWorkCallback: IBindNetWorkCallback?) {
        when {
            mIsBindingNetwork -> bindNetWorkCallback?.onResult(ErrorCode.OK)
            mHasBindNetwork -> bindNetWorkCallback?.onResult(ErrorCode.OK)
            else -> bindWifiNet(bindNetWorkCallback)
        }
    }

    fun unbindNetwork() {
        if (mHasBindNetwork) {
            unbindWifiNet()
        }
        if (mIsBindingNetwork) {
            mIsBindingNetwork = false
        }
    }

    private fun bindWifiNet(bindNetWorkCallback: IBindNetWorkCallback?) {
        if (mIsBindingNetwork) return

        mIsBindingNetwork = true
        val network = wifiNetwork
        if (network != null) {
            try {
                val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val bindSuccessful = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                    ConnectivityManager.setProcessDefaultNetwork(network)
                } else {
                    connectivityManager.bindProcessToNetwork(network)
                }

                mHasBindNetwork = bindSuccessful
                mIsBindingNetwork = false
                bindNetWorkCallback?.onResult(if (bindSuccessful) ErrorCode.OK else ErrorCode.BIND_NETWORK_FAIL)

            } catch (e: IllegalStateException) {
                mIsBindingNetwork = false
                bindNetWorkCallback?.onResult(ErrorCode.BIND_NETWORK_FAIL)
            }
        } else {
            mIsBindingNetwork = false
            bindNetWorkCallback?.onResult(ErrorCode.BIND_NETWORK_FAIL)
        }
    }

    private val wifiNetwork: Network?
        get() {
            val connManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            for (network in connManager.allNetworks) {
                val netInfo = connManager.getNetworkInfo(network)
                if (netInfo != null && netInfo.type == ConnectivityManager.TYPE_WIFI) {
                    return network
                }
            }
            return null
        }

    private fun unbindWifiNet() {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val bindSuccessful = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            ConnectivityManager.setProcessDefaultNetwork(null)
        } else {
            connectivityManager.bindProcessToNetwork(null)
        }
        if (bindSuccessful) {
            mHasBindNetwork = false
        }
    }

    private val processName: String?
        get() {
            val pid = Process.myPid()
            val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val runningAppProcessesList = manager.runningAppProcesses ?: ArrayList()
            for (process in runningAppProcessesList) {
                if (process.pid == pid) {
                    return process.processName
                }
            }
            return null
        }

    private val mOtherProcessBindNetworkReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (TextUtils.equals(intent.action, ACTION_BIND_NETWORK_NOTIFY)) {
                val isBind = intent.getBooleanExtra(EXTRA_KEY_IS_BIND, false)
                if (isBind) {
                    bindNetwork(null)
                } else {
                    unbindNetwork()
                }
            }
        }
    }

    interface IBindNetWorkCallback {
        fun onResult(errorCode: ErrorCode)
    }
}
