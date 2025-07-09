from rest_framework import serializers
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    """Serializer for the users object"""
    class Meta:
        model = User
        fields = ('id', 'email', 'first_name', 'last_name', 'is_active', 'is_staff', 'date_joined')
        read_only_fields = ('id', 'is_active', 'is_staff', 'date_joined')

class UserCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating users with validation"""
    password = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        min_length=8,
        error_messages={
            'min_length': 'Password must be at least 8 characters long.',
            'blank': 'Password cannot be empty.'
        }
    )
    password_confirm = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'},
        min_length=8,
        error_messages={
            'min_length': 'Password must be at least 8 characters long.',
            'blank': 'Please confirm your password.'
        }
    )
    
    class Meta:
        model = User
        fields = ('email', 'password', 'password_confirm', 'first_name', 'last_name')
        extra_kwargs = {
            'email': {'required': True},
            'first_name': {'required': True},
            'last_name': {'required': True}
        }
    
    def validate_email(self, value):
        """Validate email is unique and properly formatted"""
        value = value.lower().strip()
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError('A user with this email already exists.')
        return value
    
    def validate(self, attrs):
        """Validate that the two password fields match"""
        if attrs['password'] != attrs.pop('password_confirm'):
            raise serializers.ValidationError({"password_confirm": "Password fields didn't match."})
        return attrs
    
    def create(self, validated_data):
        """Create and return a new user with encrypted password"""
        try:
            user = User.objects.create_user(
                email=validated_data['email'],
                first_name=validated_data.get('first_name', ''),
                last_name=validated_data.get('last_name', ''),
                password=validated_data['password']
            )
            return user
        except Exception as e:
            raise serializers.ValidationError({"error": str(e)})

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Custom token obtain pair serializer to include user data in the response"""
    def validate(self, attrs):
        data = super().validate(attrs)
        refresh = self.get_token(self.user)
        
        data['refresh'] = str(refresh)
        data['access'] = str(refresh.access_token)
        data['user'] = {
            'id': self.user.id,
            'email': self.user.email,
            'first_name': self.user.first_name,
            'last_name': self.user.last_name,
            'is_staff': self.user.is_staff,
        }
        
        return data


class PasswordResetRequestSerializer(serializers.Serializer):
    """Serializer for password reset request"""
    email = serializers.EmailField(required=True)
    
    def validate_email(self, value):
        """Normalize email and check if it exists"""
        value = value.lower().strip()
        if not User.objects.filter(email__iexact=value).exists():
            # Don't reveal that the email doesn't exist
            return value
        return value


class PasswordResetConfirmSerializer(serializers.Serializer):
    """Serializer for password reset confirmation"""
    uid = serializers.CharField(required=True)
    token = serializers.CharField(required=True)
    new_password = serializers.CharField(
        required=True,
        min_length=8,
        style={'input_type': 'password'},
        error_messages={
            'min_length': 'Password must be at least 8 characters long.',
            'blank': 'Please enter a password.'
        }
    )
    new_password_confirm = serializers.CharField(
        required=True,
        style={'input_type': 'password'},
        error_messages={
            'blank': 'Please confirm your password.'
        }
    )
    
    def validate(self, attrs):
        """Validate that the two password fields match"""
        if attrs['new_password'] != attrs.get('new_password_confirm'):
            raise serializers.ValidationError({
                'new_password_confirm': "Passwords don't match."
            })
        return attrs


class PasswordChangeSerializer(serializers.Serializer):
    """Serializer for password change endpoint"""
    current_password = serializers.CharField(
        required=True,
        style={'input_type': 'password'},
        error_messages={
            'blank': 'Please enter your current password.'
        }
    )
    new_password = serializers.CharField(
        required=True,
        min_length=8,
        style={'input_type': 'password'},
        error_messages={
            'min_length': 'Password must be at least 8 characters long.',
            'blank': 'Please enter a new password.'
        }
    )
    new_password_confirm = serializers.CharField(
        required=True,
        style={'input_type': 'password'},
        error_messages={
            'blank': 'Please confirm your new password.'
        }
    )
    
    def validate_current_password(self, value):
        """Check that the current password is correct"""
        user = self.context['request'].user
        if not user.check_password(value):
            raise serializers.ValidationError('Current password is incorrect.')
        return value
    
    def validate(self, attrs):
        """Validate that the two new password fields match"""
        if attrs['new_password'] != attrs.get('new_password_confirm'):
            raise serializers.ValidationError({
                'new_password_confirm': "New passwords don't match."
            })
        return attrs
